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


extension String {
    subscript (i: Int) -> String {
        return String(Array(self.characters)[i])
    }
}

class ItemListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIScrollViewDelegate, ItemTableViewCellDelegate, BiddingViewControllerDelegate {
    
    
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
        
        if let imageUrl = URL(string: item.imageUrl) {
            cell.itemImageView.hnk_setImageFromURL(imageUrl, placeholder: UIImage(named: "blank")!)
        } else {
            print("Unable to get item image")
        }
        
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
        self.performSegue(withIdentifier: "checkoutSegue", sender: nil)
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
}
