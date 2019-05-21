//
//  FourthViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 3/19/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

/*citiesRef.document("SF").setData([
    "name": "San Francisco",
    "state": "CA",
    "country": "USA",
    "capital": false,
    "population": 860000,
    "regions": ["west_coast", "norcal"]
    ])*/

//
//  FourthViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 3/19/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin

class FourthViewController: UIViewController, LoginButtonDelegate {
    
    @IBAction func changeBodyweightButton(_ sender: UIButton) {
        
        let userId = UserProfile.current?.userId
        let db = Firestore.firestore()
        db.collection("users").document(userId!).getDocument{ (document, error) in
            if let document = document, document.exists {
                if let bodyweight = document.get("bodyweight") {
                    self.initializeAlert(currentBodyweight: bodyweight as! Int)
                }
                else {
                    self.initializeAlert(currentBodyweight: 0)
                }
            }
        }
        

    }
    
    func initializeAlert(currentBodyweight: Int) {
        let alert = UIAlertController(title: "What is your body weight?", message: "For calories to be calculated, we need to know your body weight (in pounds). Currently set to: \(currentBodyweight) lbs", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input your body weight here..."
        })
        
        alert.textFields?.first?.keyboardType = UIKeyboardType.numberPad
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
            if let bodyweight = alert.textFields?.first?.text {
                let userId = UserProfile.current?.userId
                let db = Firestore.firestore()
                db.collection("users").document(userId!).setData([
                    "bodyweight": Int(bodyweight)!
                    ])
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
            self.performSegue(withIdentifier: "Logout", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        loginButton.delegate = self
        
        view.addSubview(loginButton)
        
        }
    
}
