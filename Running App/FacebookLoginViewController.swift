//
//  FacebookLoginViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 3/13/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import FacebookCore
import FacebookLogin
import MapKit
import CoreLocation

class FacebookLoginViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var continueAsGuestButton: UIButton!
    
    public var currentLocation: CLLocation!
    
    public var centerLocation = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UserProfile.updatesOnAccessTokenChange = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        continueAsGuestButton.layer.cornerRadius = 3.0
        
        continueAsGuestButton.layer.shadowColor = UIColor.black.cgColor
        continueAsGuestButton.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        continueAsGuestButton.layer.shadowRadius = 2
        continueAsGuestButton.layer.shadowOpacity = 0.5


    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let accessToken = AccessToken.current {
            // User is logged in, use 'accessToken' here.
            getUserProfile()
        }
        else {
            let loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends ])
            loginButton.center = view.center
            
            
            view.addSubview(loginButton)
        }
    }
    
    func getUserProfile () {
        /*let connection = GraphRequestConnection()
        connection.add(GraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"], accessToken: AccessToken.current, httpMethod: GraphRequestHTTPMethod(rawValue: "GET")!, apiVersion: "2.8")) { httpResponse, result in
            print("result == ", result)
            switch result {
            case .success(let response):
                //print("Graph Request Succeeded: \(response)")
                //print("Custom Graph Request Succeeded: \(response)")
                //print("My facebook id is \(response.dictionaryValue?["id"])")
                print("My name is \(response.dictionaryValue?["name"])")
                self.performSegue(withIdentifier: "Login", sender: self)
                
            case .failed(let error):
                print("Graph Request Failed: \(error)")
            }
        }
        
        connection.start()*/
        
        if let currentUser = UserProfile.current {
            print("User's name is \(currentUser.firstName!)")
            self.performSegue(withIdentifier: "Login", sender: self)
        }
        else {
            UserProfile.loadCurrent({ fetchResult in
                switch fetchResult {
                case .success(let currentUser):
                    print("User's name is \(currentUser.firstName!)")
                    self.performSegue(withIdentifier: "Login", sender: self)
                case .failed(let error):
                    print("Error: \(error)")
                }
            })
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (centerLocation == true) {
            if let location = locations.first {
                let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                let region = MKCoordinateRegion(center: location.coordinate, span: span)
                mapView.setRegion(region, animated: true)
            }
            centerLocation = false
        }
        currentLocation = locations.last! as CLLocation!
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("error:: (error)")
    }
    
    
}
