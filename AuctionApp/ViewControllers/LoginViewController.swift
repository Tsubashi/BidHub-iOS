//
//  LoginViewController.swift
//  AuctionApp
//

import UIKit
import UserNotifications
import AFViewShaker
import PhoneNumberKit
import Parse

private var kAssociationKeyNextField: UInt8 = 0

extension UITextField {
    @IBOutlet var nextField: UITextField? {
        get {
            return objc_getAssociatedObject(self, &kAssociationKeyNextField) as? UITextField
        }
        set(newField) {
            objc_setAssociatedObject(self, &kAssociationKeyNextField, newField, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}

extension UIViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center

        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }

        return spinnerView
    }

    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}

class LoginViewController: UIViewController {

    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var telephoneTextField: UITextField!

    var viewShaker:AFViewShaker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewShaker = AFViewShaker(viewsArray: [nameTextField, emailTextField, telephoneTextField])
    }

    @IBAction func textFieldShouldReturn(_ textField: UITextField) {
        textField.nextField?.becomeFirstResponder()
    }
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        
        if nameTextField.text != "" && emailTextField.text != "" && telephoneTextField.text != "" {

            let sv = UIViewController.displaySpinner(onView: self.view)

            let user = PFUser()
            user["fullname"] = nameTextField.text!.lowercased()
            user.username = emailTextField.text!.lowercased()
            user.password = "test"
            user.email = emailTextField.text!.lowercased()
            user["telephone"] = telephoneTextField.text!

            nameTextField.endEditing(true)
            emailTextField.endEditing(true)
            telephoneTextField.endEditing(true)

            
            user.signUpInBackground {
                (succeeded, error) in
                if succeeded == true {
                    self.performSegue(withIdentifier: "loginToItemSegue", sender: nil)
                } else {
                    let errorString = error?.localizedDescription
                    let errorCode = error?.code
                    print("Error Signing up: \(String(describing: errorString))", terminator: "")
                    if errorCode == 202 { // 202 means that the user has already signed in once
                        PFUser.logInWithUsername(inBackground: user.username!, password: user.password!, block: { (user, error) -> Void in
                            if error == nil {
                                self.performSegue(withIdentifier: "loginToItemSegue", sender: nil)
                            }else{
                                print("Error logging in ", terminator: "")
                                self.viewShaker?.shake()
                            }
                        })
                    } else {
                        let alert = UIAlertController(title: "Error Signing In", message: errorString, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                UIViewController.removeSpinner(spinner: sv)
            }
            
        }else{
            //Can't login with nothing set
            viewShaker?.shake()
        }
    }
}
