//
//  ItemListViewController.swift
//  AuctionApp
//

import UIKit
import SVProgressHUD
import CSNotificationView
import Haneke
import NSDate_RelativeTime
import Parse
import BraintreeDropIn
import Braintree

extension String {
    subscript (i: Int) -> String {
        return String(Array(self.characters)[i])
    }
}

class ItemListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIScrollViewDelegate, ItemTableViewCellDelegate, BiddingViewControllerDelegate, CategoryViewControllerDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    var window: UIWindow?
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var items:[Item] = [Item]()
    var timer:Timer?
    var filterType: FilterType = .all
    var sizingCell: ItemTableViewCell?
    var bottomContraint:NSLayoutConstraint!
    
    var zoomOverlay: UIScrollView!
    var zoomImageView: UIImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        SVProgressHUD.setBackgroundColor(UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0))
        SVProgressHUD.setForegroundColor(UIColor(red: 242/255, green: 109/255, blue: 59/255, alpha: 1.0))
        SVProgressHUD.setRingThickness(5.0)
        
        
        let colorView:UIView = UIView(frame: CGRect(x: 0, y: -1000, width: view.frame.size.width, height: 1000))
        colorView.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0)
        tableView.addSubview(colorView)
        
        // Refresh Control
        let refreshView = UIView(frame: CGRect(x: 0, y: 10, width: 0, height: 0))
        tableView.insertSubview(refreshView, aboveSubview: colorView)
        
        refreshControl.tintColor = UIColor(red: 242/255, green: 109/255, blue: 59/255, alpha: 1.0)
        refreshControl.addTarget(self, action: #selector(ItemListViewController.reloadItems), for: .valueChanged)
        refreshView.addSubview(refreshControl)
        
        sizingCell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as? ItemTableViewCell
        
        tableView.estimatedRowHeight = 635
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.alpha = 0.0
        reloadData(false, initialLoad: true)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(ItemListViewController.reloadItems), userInfo: nil, repeats: true)
        timer?.tolerance = 10.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }
    
    /// Hack for selectors and default parameters
    func reloadItems(){
        reloadData()
    }
    
    func reloadData(_ silent: Bool = true, initialLoad: Bool = false) {
        if initialLoad {
            SVProgressHUD.show()
        }
        DataManager().sharedInstance.getItems{ (items, error) in
            
            if error != nil {
                // Error Case
                if !silent {
                    if (error?.code == 209) {
                        PFUser.logOut()
                        let frame = UIScreen.main.bounds
                        self.window = UIWindow(frame: frame)
                        //Necessary pop of view controllers after executing the previous code.
                        let loginVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                        self.window?.rootViewController=loginVC
                    }
                }
                print("Error getting items", terminator: "")
            }else{
                self.items = items
                self.filterTable(self.filterType)
            }
            self.refreshControl.endRefreshing()
            
            if initialLoad {
                SVProgressHUD.dismiss()
                UIView.animate(withDuration: 1.0, animations: { () -> Void in
                    self.tableView.alpha = 1.0
                })
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as! ItemTableViewCell
        return configureCellForIndexPath(cell, indexPath: indexPath)
    }
    
    func configureCellForIndexPath(_ cell: ItemTableViewCell, indexPath: IndexPath) -> ItemTableViewCell {
        let item = items[indexPath.row];
        
        cell.itemImageView.hnk_setImageFromURL(URL(string: item.imageUrl)!, placeholder: UIImage(named: "blank")!)
        
        cell.itemProgramNumberLabel.text = item.programNumberString
        cell.itemTitleLabel.text = item.title
        cell.itemArtistLabel.text = item.name
        cell.itemMediaLabel.text = item.media
        cell.itemSizeLabel.text = item.size
        cell.itemCalloutLabel.text = item.itemCallout
        cell.itemDescriptionLabel.text = item.itemDesctiption
        cell.itemFmvLabel.text = item.fairMarketValue
        
        if item.quantity > 1 {
            let bidsString = "$\(item.price)"
            
            cell.itemDescriptionLabel.text =
                "\(item.quantity) available! Highest \(item.quantity) bidders win. Current high bid is \(bidsString)" +
                "\n\n" + cell.itemDescriptionLabel.text!
        }
        cell.delegate = self;
        cell.item = item
        
        var price: Int?
        var lowPrice: Int?
        
        switch (item.winnerType) {
            case .single:
                price = item.price
            case .multiple:
                price = item.price
                lowPrice = item.price
        }
        
        let bidString = (item.numberOfBids == 1) ? "Bid":"Bids"
        cell.numberOfBidsLabel.text = "\(item.numberOfBids) \(bidString)"
        
        if let topBid = price {
            if let lowBid = lowPrice{
                if item.numberOfBids > 1{
                    cell.currentBidLabel.text = "$\(lowBid)-\(topBid)"
                }else{
                    cell.currentBidLabel.text = "$\(topBid)"
                }
            }else{
                cell.currentBidLabel.text = "$\(topBid)"
            }
        }else{
            cell.currentBidLabel.text = "$\(item.price)"
        }
        
        if !item.currentWinners.isEmpty && item.hasBid{
            if item.isWinning{
                cell.setWinning()
            }else{
                cell.setOutbid()
            }
        }else{
            cell.setDefault()
        }
        
        if(item.closeTime.timeIntervalSinceNow < 0.0){
            cell.dateLabel.text = "Sorry, bidding has closed"
            cell.bidNowButton.isHidden = true
        }else{
            if(item.openTime.timeIntervalSinceNow < 0.0){
                // open
                cell.dateLabel.text = "Bidding closes \((item.closeTime as NSDate).relativeTime().lowercased())."
                cell.bidNowButton.isHidden = false
            }else{
                cell.dateLabel.text = "Bidding opens \((item.openTime as NSDate).relativeTime().lowercased())."
                cell.bidNowButton.isHidden = true
            }
        }
        
        return cell
    }
    
    /// Cell Delegate
    func cellDidPressBid(_ item: Item) {
        let bidVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "BiddingViewController") as? BiddingViewController
        if let biddingVC = bidVC {
            biddingVC.delegate = self
            biddingVC.item = item
            addChildViewController(biddingVC)
            view.addSubview(biddingVC.view)
            biddingVC.didMove(toParentViewController: self)
        }
    }

    /// Image Detail Zoom
    func cellImageTapped(_ item: Item) {
        zoomImageView.frame = view.bounds
        zoomImageView.clipsToBounds = false
        zoomImageView.contentMode = .scaleAspectFit
        zoomImageView.hnk_setImageFromURL(URL(string: item.imageUrl)!, placeholder: UIImage(named: "blank")!)
        
        zoomOverlay = UIScrollView(frame: view.bounds)
        
        zoomOverlay.tag = 420
        zoomOverlay.delegate = self
        zoomOverlay.backgroundColor = UIColor.darkGray
        zoomOverlay.alwaysBounceVertical = false
        zoomOverlay.alwaysBounceHorizontal = false
        zoomOverlay.showsVerticalScrollIndicator = true
        zoomOverlay.flashScrollIndicators()
        
        zoomOverlay.minimumZoomScale = 1.0
        zoomOverlay.maximumZoomScale = 6.0
        
        let backButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(ItemListViewController.pressedClose(_:)))
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = backButton
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white

        segmentControl.isHidden = true
        
        zoomOverlay.addSubview(zoomImageView)
        
        self.view.addSubview(zoomOverlay)
        setupZoomGestureRecognizer()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = zoomImageView.frame.size
        let scrollViewSize = zoomOverlay.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        zoomOverlay.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    func setupZoomGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ItemListViewController.handleZoomImageDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        zoomOverlay.addGestureRecognizer(doubleTap)
    }
    
    func handleZoomImageDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if (zoomOverlay.zoomScale > zoomOverlay.minimumZoomScale) {
            zoomOverlay.setZoomScale(zoomOverlay.minimumZoomScale, animated: true)
        } else {
            zoomOverlay.setZoomScale(zoomOverlay.maximumZoomScale, animated: true)
        }
    }
    
    func pressedClose(_ sender: UIButton!) {
        self.segmentControl.isHidden = false
        
        if let viewWithTag = self.view.viewWithTag(420) {
            viewWithTag.removeFromSuperview()
        }
        
        let btnName = UIButton()
        btnName.setImage(UIImage(named: "HSLogOutIcon"), for: UIControlState())
        btnName.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnName.addTarget(self, action: #selector(ItemListViewController.logoutPressed(_:)), for: .touchUpInside)
        
        let leftBarButton = UIBarButtonItem(customView: btnName)
        navigationItem.leftBarButtonItem = leftBarButton
        navigationItem.rightBarButtonItem = nil
    }

    /// Actions
    @IBAction func logoutPressed(_ sender: AnyObject) {
        let logoutAlert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to log out? If you need to log in again, make sure to use the same email address!", preferredStyle: UIAlertControllerStyle.alert)

        logoutAlert.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (action: UIAlertAction!) in
            PFUser.logOut()
            self.performSegue(withIdentifier: "logoutSegue", sender: nil)
        }))

        logoutAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //self.didTapBackground(bidAlert)
        }))
        present(logoutAlert, animated: true, completion: nil)

    }

    @IBAction func checkoutPressed(_ sender: Any) {
        self.view.endEditing(true) // If we try to pop up the payment bar while the keyboard is up, it crashes.
        fetchClientToken()
    }
    
    @IBAction func segmentBarValueChanged(_ sender: AnyObject) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        let segment = sender as! UISegmentedControl
        switch(segment.selectedSegmentIndex) {
            case 0:
                filterTable(.all)
            case 1:
                filterTable(.noBids)
            case 2:
                filterTable(.myItems)
            default:
                filterTable(.all)
        }
    }

    // Braintree functions
    func fetchClientToken() {
        // TODO: Switch this URL to your own authenticated API
        let clientTokenURL = NSURL(string: "https://auction.ucrpc.org/payment/client_token")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            let httpResponse = response as? HTTPURLResponse
            if error == nil && httpResponse?.statusCode == 200 {
                if let usableData = data {
                    let clientToken = String(data: usableData, encoding: String.Encoding.utf8)
                    self.showPaymentDropIn(clientTokenOrTokenizationKey: clientToken!)
                }
            } else {
                // Handle Errors
                self.showError("Try as I might, I couldn't get a token from the payment server. Try again, but if it still isn't working go ahead and inform a moderator. It might be a problem on our end.")
                print("ERROR!")
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

    // Extras
    func filterTable(_ filter: FilterType) {
        filterType = filter
        self.items = DataManager().sharedInstance.applyFilter(filter)
        self.tableView.reloadData()
    }
    
    func bidOnItem(_ item: Item, maxBid: Int) {
        SVProgressHUD.show()
        
        DataManager().sharedInstance.bidOn(item, maxBid: maxBid) { (success, errorString) -> () in
            if success {
                print("Woohoo, the bid went through", terminator: "")
                self.items = DataManager().sharedInstance.allItems
                self.reloadData()
                SVProgressHUD.dismiss()
            }else{
                self.showError(errorString)
                self.reloadData()
                SVProgressHUD.dismiss()
            }
        }
    }

    func showError(_ errorString: String) {
        if let _: AnyClass = NSClassFromString("UIAlertController") {
            // make and use a UIAlertController
            let alertView = UIAlertController(title: "Uh-Oh!", message: errorString, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                print("Ok Pressed", terminator: "")
            })
            
            alertView.addAction(okAction)
            self.present(alertView, animated: true, completion: nil)
        }
        else {
            // make and use a UIAlertView
            let alertView = UIAlertView(title: "Error", message: errorString, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok")
            alertView.show()
        }
    }
    
    /// Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filterTable(.all)
        }else{
            filterTable(.search(searchTerm:searchText))
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.segmentBarValueChanged(segmentControl)
        searchBar.resignFirstResponder()
    }
    
    /// Bidding VC
    func biddingViewControllerDidBid(_ viewController: BiddingViewController, onItem: Item, maxBid: Int){
        viewController.view.removeFromSuperview()
        bidOnItem(onItem, maxBid: maxBid)
    }
    
    func biddingViewControllerDidCancel(_ viewController: BiddingViewController){
        viewController.view.removeFromSuperview()
    }
    
    /// Category VC
    func categoryViewControllerDidFilter(_ viewController: CategoryViewController, onCategory: String){
        viewController.view.removeFromSuperview()
        filterTable(.category(filterValue: onCategory))
    }
    
    func categoryViewControllerDidCancel(_ viewController: CategoryViewController){
        viewController.view.removeFromSuperview()
        self.segmentControl.selectedSegmentIndex = 0
        segmentBarValueChanged(self.segmentControl)
    }
}
