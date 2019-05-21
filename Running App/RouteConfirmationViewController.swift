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
    
    public var loadedRouteCoords: [CLLocationCoordinate2D]!
    
    public var loadedRouteInstructions: [Instruction]!
    
    public var startingLocation: CLLocationCoordinate2D!
    
    public var endingLocation: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    /*@IBAction func doneButton(_ sender: UIButton) {
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
    }*/
    
    @IBAction func cancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func loadRouteButton(_ sender: UIButton) {
        //let presenter = self.parent?.parent?.children.first as! FilterTableViewController
        let presenter = self.presentingViewController?.children.first as! FilterTableViewController
         let presentersPresenter = presenter.presentingViewController as! TabBarController
         let secondViewController = presentersPresenter.viewControllers![1] as! SecondViewController
         
         secondViewController.loadedRouteCoords = loadedRouteCoords
         secondViewController.loadedRouteInstructions = loadedRouteInstructions
         secondViewController.startingLocation = startingLocation
         secondViewController.endingLocation = endingLocation
         secondViewController.mapView.removeOverlays(secondViewController.mapView.overlays)
         self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
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
        
        if (loadedRouteCoords != nil) {
            mapView.removeAnnotations(mapView.annotations)
            startingLocation = loadedRouteCoords[0]
            endingLocation = loadedRouteCoords[loadedRouteCoords.count-1]
            //Round Trip
            if (startingLocation.latitude == endingLocation.latitude && startingLocation.longitude == endingLocation.longitude) {
                let startingAnnotation = MKPointAnnotation()
                startingAnnotation.coordinate = startingLocation
                mapView.addAnnotation(startingAnnotation)
                /*let endingAnnotation = MKPointAnnotation()
                 endingAnnotation.coordinate = loadedRouteCoords[loadedRouteCoords.count-1]
                 mapView.addAnnotation(endingAnnotation)*/
            }
                //Not Round Trip
            else {
                let startingAnnotation = MKPointAnnotation()
                startingAnnotation.coordinate = startingLocation
                mapView.addAnnotation(startingAnnotation)
                let endingAnnotation = MKPointAnnotation()
                endingAnnotation.coordinate = endingLocation
                mapView.addAnnotation(endingAnnotation)
            }
            let myPolyline = MKPolyline(coordinates: self.loadedRouteCoords, count: self.loadedRouteCoords.count)
            
            self.mapView.addOverlay(myPolyline)
            
            /*
            let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
            self.mapView.setRegion(region, animated: true)*/
            
            for coord in loadedRouteCoords {
                print("Coordinate: Lat: \(coord.latitude), Long: \(coord.longitude)")
            }
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
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("error:: (error)")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        }
        else {
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            if (annotation.coordinate.latitude == startingLocation.latitude && annotation.coordinate.longitude == startingLocation.longitude) {
                annotationView.markerTintColor = UIColor.init(red: 0.0/255.0, green: 192.0/255.0, blue: 51.0/255.0, alpha: 1)
            }
            else if (annotation.coordinate.latitude == endingLocation.latitude && annotation.coordinate.longitude == endingLocation.longitude) {
                annotationView.markerTintColor = UIColor.red
            }
            return annotationView
        }
    }
}
