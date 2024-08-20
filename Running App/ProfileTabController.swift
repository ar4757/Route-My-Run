//
//  ProfileTabController.swift
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
//  ProfileTabController.swift
//  Running App
//
//  Created by Andrew Ratz on 3/19/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin

class ProfileTabController: UIViewController, LoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: (any Error)?) {
        if let error = error {
            print("Encountered Erorr: \(error)")
        } else if let result = result, result.isCancelled {
            print("Cancelled")
        } else {
            print("Logged In")
            self.getUserProfile()
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        self.performSegue(withIdentifier: "Logout", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loginButton = FBLoginButton()
        loginButton.center = view.center
        loginButton.delegate = self
        view.addSubview(loginButton)
    }
    
    @IBAction func changeBodyweightButton(_ sender: UIButton) {
        
        let userId = AccessToken.current?.userID
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
                let userId = AccessToken.current?.userID
                let db = Firestore.firestore()
                db.collection("users").document(userId!).setData([
                    "bodyweight": Int(bodyweight)!
                    ])
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func getUserProfile () {
        guard AccessToken.current != nil else { return }

        let request = GraphRequest(graphPath: "me", parameters: ["fields":"first_name,last_name,id,picture"])
        request.start() { connection, result, error in
            if let result = result as? [String: Any], error == nil {
                print("fetched user: \(result)")
                let decoder = JSONDecoder()
                do {
                    let jsonData = try? JSONSerialization.data(withJSONObject:result)
                    let user = try decoder.decode(FBUser.self, from: jsonData!)
                    MyDataStore.user = user
                } catch {
                    print(error)
                }
            }
        }
    }
}
