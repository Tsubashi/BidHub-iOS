//
//  BiddingViewController.swift
//  AuctionApp
//

import UIKit
import IHKeyboardAvoiding

protocol BiddingViewControllerDelegate {
    func biddingViewControllerDidBid(_ viewController: BiddingViewController, onItem: Item, maxBid: Int)
    func biddingViewControllerDidCancel(_ viewController: BiddingViewController)
}

private enum BiddingViewControllerState{
    case custom
    case standard
}

class BiddingViewController: UIViewController {

    @IBOutlet var darkView: UIView!
    @IBOutlet var popUpContainer: UIView!
    @IBOutlet var predifinedButtonsContainerView: UIView!
    @IBOutlet var customBidButton: UIButton!
    @IBOutlet var customBidTextField: UITextField!
    @IBOutlet var plusOneButton: UIButton!
    @IBOutlet var plusTenButton: UIButton!
    @IBOutlet var plusFiveButton: UIButton!
    var delegate: BiddingViewControllerDelegate?
    var item: Item?
    var startPrice = 0
    fileprivate var state :BiddingViewControllerState = .standard
    
    var incrementOne = 0
    var incrementFive = 0
    var incrementTen = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customBidTextField.alpha = 0.0
        
        if let itemUW = item{
            
            incrementOne  = itemUW.priceIncrement
            incrementFive = 2*itemUW.priceIncrement
            incrementTen  = 5*itemUW.priceIncrement
            
            switch(itemUW.winnerType){
            case .multiple:
                if itemUW.currentWinners.isEmpty{
                    let openingBid = itemUW.price - itemUW.priceIncrement
                    setupForSingle(openingBid)
                }else{
                    setupForSingle(itemUW.price)
                }
            case .single:
                if itemUW.currentWinners.isEmpty{
                    let openingBid = itemUW.price - itemUW.priceIncrement
                    setupForSingle(openingBid)
                }else{
                    setupForSingle(itemUW.price)
                }
            }
            
            popUpContainer.backgroundColor = UIColor.white
            popUpContainer.layer.cornerRadius = 5.0
            
            customBidButton.titleLabel?.font = UIFont(name: "Avenir-Light", size: 18.0)!
            customBidButton.setTitleColor(UIColor(red: 33/225, green: 161/225, blue: 219/225, alpha: 1), for: UIControlState())
            
            customBidTextField.font = UIFont(name: "Avenir-Light", size: 24.0)
            customBidTextField.textColor = UIColor(red: 33/225, green: 161/225, blue: 219/225, alpha: 1)
            customBidTextField.textAlignment = .center
            
            //IHKeyboardAvoiding.setBuffer(20)
            //IHKeyboardAvoiding.setPadding(20)
            //IHKeyboardAvoiding.setAvoidingView(view, withTarget: popUpContainer)
            
            animateIn()
        }
    }

    @IBAction func didTapBackground(_ sender: AnyObject) {
        if delegate != nil {
            
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.popUpContainer.transform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01);
                self.darkView.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.delegate!.biddingViewControllerDidCancel(self)
            })
            
        }
    }
    func setupForSingle(_ startAmount: Int) {
        
        startPrice = startAmount
        
        let bidAttrs = [NSFontAttributeName : UIFont(name: "Avenir-Light", size: 14.0)! , NSForegroundColorAttributeName: UIColor.gray] as NSDictionary
        let otherAttrs = [NSFontAttributeName : UIFont(name: "Avenir-Light", size: 22.0)!, NSForegroundColorAttributeName: UIColor(red: 33/225, green: 161/225, blue: 219/225, alpha: 1)]
        
        plusOneButton.titleLabel?.textAlignment = .center
        plusFiveButton.titleLabel?.textAlignment = .center
        plusTenButton.titleLabel?.textAlignment = .center

        let one = NSMutableAttributedString(string: "BID\n", attributes: bidAttrs as! [String: NSObject])
        one.append(NSMutableAttributedString(string: "$\(startAmount + incrementOne)", attributes: otherAttrs))
        plusOneButton.setAttributedTitle(one, for: UIControlState())
        
        let five = NSMutableAttributedString(string: "BID\n", attributes: bidAttrs as! [String: NSObject])
        five.append(NSMutableAttributedString(string: "$\(startAmount + incrementFive)", attributes: otherAttrs))
        plusFiveButton.setAttributedTitle(five, for: UIControlState())
        
        let ten = NSMutableAttributedString(string: "BID\n", attributes: bidAttrs as! [String: NSObject])
        ten.append(NSMutableAttributedString(string: "$\(startAmount + incrementTen)", attributes: otherAttrs))
        plusTenButton.setAttributedTitle(ten, for: UIControlState())
        
   
    }
    
    func setupForMultiple() {
        self.customBidTextField.alpha = 1.0
        self.predifinedButtonsContainerView.alpha = 0.0
        self.customBidButton.setTitle("Max Bid", for: UIControlState())
        state = .custom
    }

    func didSelectAmount(_ bidType: BidType) {
        
        var maxBid = 0
        switch bidType {
        case .custom(let total):
            maxBid = total
        case .extra(let aditional):
            maxBid = startPrice + aditional
        }
        
        let bidAlert = UIAlertController(title: "Confirm $\(maxBid) Bid", message: "You didn't think we'd let you bid $\(maxBid) without confirming it, did you?", preferredStyle: UIAlertControllerStyle.alert)
        
        bidAlert.addAction(UIAlertAction(title: "Bid", style: .default, handler: { (action: UIAlertAction!) in
            if self.delegate != nil {
                if let itemUW = self.item {
                    
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        self.popUpContainer.transform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01);
                        self.darkView.alpha = 0
                        }, completion: { (finished: Bool) -> Void in
                            self.delegate!.biddingViewControllerDidBid(self, onItem: itemUW, maxBid: maxBid)
                    })
                    
                    
                }
            }
        }))
        
        bidAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //self.didTapBackground(bidAlert)
        }))
        
        present(bidAlert, animated: true, completion: nil)
        
    }
    
    @IBAction func customAmountPressed(_ sender: AnyObject) {
        
        switch state {
            case .custom:
                if let maxBid = Int(customBidTextField.text!){
                    didSelectAmount(.custom(maxBid))
                }else{
                    didTapBackground("" as AnyObject)
                }
            case .standard:
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.setupForMultiple()
                    self.customBidTextField.becomeFirstResponder()
                })
        }
    }

    @IBAction func bidOnePressed(_ sender: AnyObject) {
        didSelectAmount(.extra(incrementOne))
    }

    @IBAction func bidFivePressed(_ sender: AnyObject) {
        didSelectAmount(.extra(incrementFive))
    }
    
    @IBAction func bidTenPressed(_ sender: AnyObject) {
        didSelectAmount(.extra(incrementTen))
    }
    
    func animateIn(){
        popUpContainer.transform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01);
        
        UIView.animate(withDuration: 0.5,
            delay: 0.0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.curveLinear,
            animations: {
                self.popUpContainer.transform = CGAffineTransform.identity
                self.darkView.alpha = 1.0
                
            },
            completion: { (fininshed: Bool) -> () in

            }
        )
    }


}
