//
//  RouteConfirmation.swift
//  Running App
//
//  Created by Andrew Ratz on 4/8/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GraphHopperRouting

class RouteConfirmationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func doneButton(_ sender: UIButton) {
        if (annotation != nil) {
            let presenter = self.presentingViewController as! UINavigationController
            let presenterChild = presenter.viewControllers[0] as! FilterTableViewController
            if (starting == true) {
                presenterChild.startingLocation = annotation.coordinate
            }
            else {
                presenterChild.endingLocation = annotation.coordinate
            }
            presenterChild.lookUpLocations()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public var currentLocation: CLLocation!
    
    public var centerLocation = true
    
    public var tapGesture: UIGestureRecognizer!
    
    public var annotation: MKPointAnnotation!
    
    public var starting = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self
        
        self.mapView.layer.cornerRadius = 32.0
        self.mapView.clipsToBounds = true
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.mapViewTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)
        print(starting)
        
        let presenter = self.presentingViewController as! UINavigationController
        let presenterChild = presenter.viewControllers[0] as! FilterTableViewController
        if (starting == true && presenterChild.startingLocation != nil) {
            annotation = MKPointAnnotation()
            annotation.coordinate = presenterChild.startingLocation
            mapView.addAnnotation(annotation)
        }
        else if (starting == false && presenterChild.endingLocation != nil) {
            annotation = MKPointAnnotation()
            annotation.coordinate = presenterChild.endingLocation
            mapView.addAnnotation(annotation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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
        if (annotation == nil) {
            annotation = MKPointAnnotation()
            annotation.coordinate = currentLocation.coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("error:: (error)")
    }
    
    @objc func mapViewTapped(_ sender: UITapGestureRecognizer) {
        if (annotation != nil) {
            mapView.removeAnnotation(annotation)
        }
        let location = tapGesture.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            if (starting == true) {
                annotationView.markerTintColor = UIColor.init(red: 0.0/255.0, green: 192.0/255.0, blue: 51.0/255.0, alpha: 1)
            }
            else {
                annotationView.markerTintColor = UIColor.red
            }
            return annotationView
        }
    }
}
