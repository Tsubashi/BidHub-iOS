//
//  ItemManager.swift
//  AuctionApp
//

import UIKit
import Parse

class DataManager: NSObject {
 
    var allItems: [Item] = [Item]()

    var timer:Timer?
    
    var sharedInstance : DataManager {
        struct Static {
            static let instance : DataManager = DataManager()
        }
        
        return Static.instance
    }
    
    
    func getItems(_ completion: @escaping ([Item], NSError?) -> ()){
        let query = Item.query()
        query!.limit = 1000
        query!.addAscendingOrder("programNumber")
        query!.findObjectsInBackground { (results, error) -> Void in
            if error != nil{
                print("Error!! \(String(describing: error))", terminator: "")
                completion([Item](), error as NSError?)
            }else{
                if let itemsUW = results as? [Item] {
                    self.allItems = itemsUW
                    completion(itemsUW, nil)
                }
            }
        }
    }
    
    func searchForQuery(_ query: String) -> ([Item]) {
        return applyFilter(.search(searchTerm: query))
    }
    
    func applyFilter(_ filter: FilterType) -> ([Item]) {
        return allItems.filter({ (item) -> Bool in
            return filter.predicate.evaluate(with: item)
        })
    }
    
    func bidOn(_ item:Item, maxBid: Int, completion: @escaping (Bool, _ errorCode: String) -> ()){
        
        let user = PFUser.current()
        
        Bid(email: user!.email!, name: user!["fullname"] as! String, telephone: user!["telephone"] as! String, maxBid: maxBid, itemId: item.objectId!)
        .saveInBackground { (success, error) -> Void in
            
            if error != nil {
                if (error?.localizedDescription != nil) {
                    completion(false, (error?.localizedDescription)!)
                }else{
                    completion(false, "")
                }
                return
            }
            
            let newItemQuery: PFQuery = Item.query()!
            newItemQuery.whereKey("objectId", equalTo: item.objectId!)
            newItemQuery.getFirstObjectInBackground(block: { (item, error) -> Void in
                
                if let itemUW = item as? Item {
                    self.replaceItem(itemUW)
                }
                completion(true, "")
            })
            
            let channel = item.objectId
            PFPush.subscribeToChannel(inBackground: channel!, block: { (success, error) -> Void in
                
            })
        }
    }
    
    func replaceItem(_ item: Item) {
        allItems = allItems.map { (oldItem) -> Item in
            if oldItem.objectId == item.objectId {
                return item
            }
            return oldItem
        }
    }
}


enum FilterType: CustomStringConvertible {
    case all
    case noBids
    case myItems
    case search(searchTerm: String)
    
    var description: String {
        switch self{
            case .all:
                return "All"
            case .noBids:
                return "NoBids"
            case .myItems:
                return "My Items"
            case .search:
                return "Searching"
        }
    }
    
    var predicate: NSPredicate {
        switch self {
            case .all:
                return NSPredicate(value: true)
            case .noBids:
                return NSPredicate(block: { (object, bindings) -> Bool in
                    if let item = object as? Item {
                        return item.numberOfBids == 0
                    }
                    return false
                })
            case .myItems:
                return NSPredicate(block: { (object, bindings) -> Bool in
                    if let item = object as? Item {
                        return item.hasBid
                    }
                    return false
                })
            case .search(let searchTerm):
                return NSPredicate(format: "(artist CONTAINS[c] %@) || (title CONTAINS[c] %@) || (itemDesctiption CONTAINS[c] %@) || (media CONTAINS[c] %@) || (programNumberString CONTAINS[c] %@)", searchTerm, searchTerm, searchTerm, searchTerm, searchTerm)
        }
    }
}
