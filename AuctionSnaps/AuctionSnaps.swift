//
//  AuctionSnaps.swift
//  AuctionSnaps
//
//  Created by Chandler Scott on 4/11/18.
//  Copyright © 2018 org.ucrpc. All rights reserved.
//

import XCTest

class AuctionSnaps: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false


        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        addUIInterruptionMonitor(withDescription: "Push Notifications") { (alert) -> Bool in
            /* Dismiss Location Dialog */
            if alert.collectionViews.buttons["Allow"].exists {
                alert.collectionViews.buttons["Allow"].tap()
                return true
            }
            return false
        }
        //snapshot("0Launch")

        let nameTextField = app.textFields["First and Last Name"]
        nameTextField.tap()
        nameTextField.typeText("tester")

        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("tester@1.com")

        let phoneTextField = app.textFields["Telephone"]
        phoneTextField.tap()
        phoneTextField.typeText("000")

        app.buttons["Start"].tap()
        sleep(1)
        //snapshot("0Launch")
        app.navigationBars["Auction.ItemListView"].buttons["LogOut"].tap()
        app.alerts["Confirm Logout"].buttons["Logout"].tap()



    }
    
}
