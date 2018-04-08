//
//  CheckoutViewController.swift
//  AuctionApp
//

import Foundation
import BraintreeDropIn
import Braintree
import SVProgressHUD

class CheckoutTableViewCell: UITableViewCell {
    
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var itemName: UILabel!
    @IBOutlet var itemPurchasedStatus: UILabel!
    @IBOutlet var itemPrice: UILabel!
    
    func viewDidLoad() {
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        itemImageView.contentMode = .scaleAspectFill
        itemImageView.clipsToBounds = true
    }
}

class CheckoutViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var totalPriceLabel: UILabel!
    
    var sizingCell: CheckoutTableViewCell?
    var itemsWon:[Item] = []
    var totalPrice:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.setBackgroundColor(UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.25))
        SVProgressHUD.setForegroundColor(UIColor(red: 242/255, green: 109/255, blue: 59/255, alpha: 1.0))
        SVProgressHUD.setRingThickness(5.0)
        SVProgressHUD.show()
        
        sizingCell = tableView.dequeueReusableCell(withIdentifier: "CheckoutTableViewCell") as? CheckoutTableViewCell
        
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableViewAutomaticDimension
        
        DataManager().sharedInstance.getItems{ (items, error) in
            if error != nil {
                // Error Case
                self.showError("I'm afraid I couldn't get the latest list of items, so I've no idea if you have won anything. Make sure you are connected to the internet and try again.", extraInfo: "Error: '\(String(describing: error))'", onOk: {self.dismiss(animated: true, completion: nil)})
                print("Error getting items", terminator: "")
                self.dismiss(animated: true, completion: nil)
            } else {
                for item in items {
                    if item.isWinning /* TODO: Check that bidding is closed and item is not yet paid for */{
                        self.itemsWon.append(item)
                        self.totalPrice += item.price
                    }
                }
            }
        }
        totalPriceLabel.text = String("$\(totalPrice)")
        SVProgressHUD.dismiss()
    }
    
    // Actions
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func checkoutPressed(_ sender: Any) {
        SVProgressHUD.show()
        fetchClientToken()
        SVProgressHUD.dismiss(withDelay: 3)
    }
    
    // TableView Data functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsWon.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as! CheckoutTableViewCell
        let item = itemsWon[indexPath.row];
        
        if let imageUrl = URL(string: item.imageUrl) {
            cell.itemImageView.hnk_setImageFromURL(imageUrl, placeholder: UIImage(named: "blank")!)
        } else {
            print("Unable to get item image")
        }
        
        cell.itemName.text = item.name
        cell.itemPrice.text = String(item.price)
        cell.itemPurchasedStatus.text = ""
        
        return cell
    }
    
    // Braintree functions
    func fetchClientToken() {
        let clientTokenURL = NSURL(string: "https://auction.ucrpc.org/payment/client_token")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            let httpResponse = response as? HTTPURLResponse
            if error == nil && httpResponse!.statusCode == 200 {
                if let usableData = data {
                    let clientToken = String(data: usableData, encoding: String.Encoding.utf8)
                    self.showPaymentDropIn(clientTokenOrTokenizationKey: clientToken!)
                }
            } else {
                // Handle Errors
                self.showError("Try as I might, I couldn't get a token from the payment server. Try again, but if it still isn't working go ahead and inform a moderator. It might be a problem on our end.", extraInfo: "Error: '\(String(describing: error))', status: '\(String(describing: httpResponse?.statusCode))'")
            }
            }.resume()
    }
    
    func showPaymentDropIn(clientTokenOrTokenizationKey: String) {
        let request =  BTDropInRequest()
        let dropIn = BTDropInController(authorization: clientTokenOrTokenizationKey, request: request)
        { (controller, result, error) in
            if (error != nil) {
                print("ERROR")
            } else if (result?.isCancelled == true) {
                print("CANCELLED")
            } else if let result = result {
                // Use the BTDropInResult properties to update your UI
                // result.paymentOptionType
                // print(result.paymentMethod)
                // result.paymentIcon
                // result.paymentDescription
                print(result.paymentDescription)
                self.showError("Result: \(result)")
                self.postNonceToServer(paymentMethodNonce: result.paymentMethod!.nonce)
            }
            controller.dismiss(animated: true, completion: nil)
        }
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    func postNonceToServer(paymentMethodNonce: String) {
        // Update URL with your server
        let paymentURL = URL(string: "https://auction.ucrpc.org/payment/checkout")!
        var request = URLRequest(url: paymentURL)
        request.httpBody = "payment_method_nonce=\(paymentMethodNonce)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
            // TODO: Handle success or failure
            }.resume()
    }
    
    // Extra Functions
    func showError(_ errorString: String, extraInfo: String? = nil, onOk: (() -> Void)? = nil) {
        if let _: AnyClass = NSClassFromString("UIAlertController") {
            // make and use a UIAlertController
            let alertView = UIAlertController(title: "Uh-Oh!", message: errorString, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                onOk?()
            })
            alertView.addAction(okAction)
            
            if let extraInfo = extraInfo {
                let moreInfoAction = UIAlertAction(title: "More Info", style: .default, handler: { (action) -> Void in
                    let secondAlertView = UIAlertController(title: "Technical Details", message: extraInfo, preferredStyle: .alert)
                    let secondOkAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                        onOk?()
                    })
                    secondAlertView.addAction(secondOkAction)
                    self.present(secondAlertView, animated: true){}
                })
                alertView.addAction(moreInfoAction)
            }
            
            self.present(alertView, animated: true, completion: nil)
        }
        else {
            // make and use a UIAlertController
            let alert = UIAlertController(title: "Uh-Oh!", message:errorString, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) { _ in }
            alert.addAction(action)
            self.present(alert, animated: true){}
        }
    }
}
