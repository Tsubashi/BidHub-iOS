//
//  CategoryViewController.swift
//  AuctionApp
//
//  Created by Michael Fitzpatrick on 5/28/17.
//  Copyright © 2017 fitz.guru. All rights reserved.
//

import Foundation
import UIKit

protocol CategoryViewControllerDelegate {
    func categoryViewControllerDidFilter(_ viewController: CategoryViewController, onCategory: String)
    func categoryViewControllerDidCancel(_ viewController: CategoryViewController)
}

class CategoryViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet var darkView: UIView!
    @IBOutlet var categoryPicker: UIPickerView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var doneButton: UIBarButtonItem!
    
    var delegate: CategoryViewControllerDelegate?

    var categoryNames = ["Art - All", "Art - Paintings", "Art - Photography", "Art - Prints, Drawings, & Other", "Experiences - All", "Experiences - Fashion", "Experiences - Sports", "Experiences - Travel"]
    var categoryValues = ["art", "painting", "photo", "pdo", "other", "fashion", "sport", "travel"]
 
    /// UIPickerViewDataSource Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryNames.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        return
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        animateIn()
    }
    
    @IBAction func didTapBackground(_ sender: AnyObject) {
        animateOut()
    }
    
    @IBAction func didPressCancel(_ sender: AnyObject) {
        animateOut()
    }

    @IBAction func didPressDone(_ sender: AnyObject) {
        let category = categoryValues[categoryPicker.selectedRow(inComponent: 0)] as String
        if self.delegate != nil {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.darkView.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.delegate!.categoryViewControllerDidFilter(self, onCategory: category)
            })
        }
    }

    func didSelectCategory(_ category: String) {
        if self.delegate != nil {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.darkView.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.delegate!.categoryViewControllerDidFilter(self, onCategory: category)
            })
        }
    }
    
    func animateIn(){
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.0,
            options: UIViewAnimationOptions.curveLinear,
            animations: {
                self.darkView.alpha = 1.0
            },
            completion: { (fininshed: Bool) -> () in })
    }
    
    func animateOut(){
        if delegate != nil {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.darkView.alpha = 0
            }, completion: { (finished: Bool) -> Void in
                self.delegate!.categoryViewControllerDidCancel(self)
            })
            
        }
    }
}
