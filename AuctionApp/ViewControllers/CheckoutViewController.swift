//
//  CheckoutViewController.swift
//  AuctionApp
//
//  Created by Scott Family on 4/7/18.
//  Copyright © 2018 fitz.guru. All rights reserved.
//

import Foundation
import BraintreeDropIn
import Braintree


class CheckoutViewController: UIViewController {
    
    // Actions
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func checkoutPressed(_ sender: Any) {
        fetchClientToken()
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
    func showError(_ errorString: String, extraInfo: String? = nil) {
        if let _: AnyClass = NSClassFromString("UIAlertController") {
            // make and use a UIAlertController
            let alertView = UIAlertController(title: "Uh-Oh!", message: errorString, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) -> Void in
                // Do Nothing
            })
            alertView.addAction(okAction)
            
            if let extraInfo = extraInfo {
                let moreInfoAction = UIAlertAction(title: "More Info", style: .default, handler: { (action) -> Void in
                    let secondAlertView = UIAlertController(title: "Technical Details", message: extraInfo, preferredStyle: .alert)
                    let secondOkAction = UIAlertAction(title: "Ok", style: .default)
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
