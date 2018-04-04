
//
//  AppDelegate.swift
//  AuctionApp
//

import UIKit
import UserNotifications
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let configuration = ParseClientConfiguration {
            $0.applicationId = "UCRPCAuction"
            $0.clientKey = "bba0f20f-7d2a-48c5-bd91-a0061da55985"
            $0.server = "https://auction.ucrpc.org/parse"
            //$0.localDatastoreEnabled = true // If you need to enable local data store
        }
        Parse.initialize(with: configuration)

        let frame = UIScreen.main.bounds
        window = UIWindow(frame: frame)
        
        let currentUser = PFUser.current()
        if currentUser != nil {
            let itemVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController() as? UINavigationController
            window?.rootViewController=itemVC

            // Write user email to installation table for push targetting
            let currentInstalation = PFInstallation.current()
            currentInstalation?["email"] = currentUser!.email
            currentInstalation?.saveInBackground(block: nil)
        } else {
            //Prompt User to Login
            let loginVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            window?.rootViewController=loginVC
        }
            
        window?.makeKeyAndVisible()

        // Push Notifications
        let types: UIUserNotificationType = [.alert, .badge, .sound]
        let settings = UIUserNotificationSettings(types: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let currentInstalation = PFInstallation.current()
        
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        
        for i in 0 ..< deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        print("tokenString: \(tokenString) \r\n", terminator: "")
        
        currentInstalation?.setDeviceTokenFrom(deviceToken)
        currentInstalation?.saveInBackground(block: nil)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("Failed to register for remote notifications: \(error.localizedDescription)")
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PFPush.handle(userInfo)
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        PFPush.handle(userInfo)
        //TODO: Reload Item View Controller Data
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        application.applicationIconBadgeNumber = 0
    }
}



