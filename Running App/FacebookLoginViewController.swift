//
//  FacebookLoginViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 3/13/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import FacebookCore
import FacebookLogin

class PictureSubParams : Codable {
    var url: String = ""
}

class PictureParams : Codable {
    var data: PictureSubParams = PictureSubParams()
}

class FBUser : Codable {
    var first_name: String = ""
    var last_name: String = ""
    var picture: PictureParams = PictureParams()
}

class MyDataStore {
    static var user: FBUser = FBUser()
}

class FacebookLoginViewController: UIViewController, LoginButtonDelegate {
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
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        
    }
    
            
    @IBOutlet weak var continueAsGuestButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        continueAsGuestButton.layer.cornerRadius = 3.0
        
        continueAsGuestButton.layer.shadowColor = UIColor.black.cgColor
        continueAsGuestButton.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        continueAsGuestButton.layer.shadowRadius = 2
        continueAsGuestButton.layer.shadowOpacity = 0.5


    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let accessToken = AccessToken.current, !accessToken.isExpired {
            // User is logged in, use 'accessToken' here.
            getUserProfile()
        }
        else {
            let loginButton = FBLoginButton()
            loginButton.permissions = ["public_profile", "email", "user_friends"]
            loginButton.center = view.center
            loginButton.delegate = self
            view.addSubview(loginButton)
        }
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
                self.performSegue(withIdentifier: "Login", sender: self)
            }
        }
    }
}
