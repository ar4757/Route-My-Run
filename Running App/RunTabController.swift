//
//  RunTabController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/15/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import FacebookCore
import FacebookLogin
import AVFoundation
import GraphHopperRouting

class RunTabController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var beginRunButton: UIButton!
    
    @IBOutlet weak var findARouteButton: UIButton!
    
    @IBOutlet weak var finishRunButton: UIButton!
    
    @IBOutlet weak var pauseRunButton: UIButton!
    
    @IBOutlet weak var statsOverlayView: UIView!
    
    @IBOutlet weak var statsOverlayBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeMinutesLabel: UILabel!
    @IBOutlet weak var timeSecondsLabel: UILabel!
    @IBOutlet weak var paceMinutesLabel: UILabel!
    @IBOutlet weak var paceSecondsLabel: UILabel!
    
    public var paused = true
    
    public var previousLocation: CLLocation!

    public var currentLocation: CLLocation!
    
    public var centerLocation = true
    
    public var loadedRouteCoords: [CLLocationCoordinate2D]!
    
    public var loadedRouteInstructions: [Instruction]!
    
    public var startingLocation: CLLocationCoordinate2D!
    
    public var endingLocation: CLLocationCoordinate2D!
    
    public var timeTimer = Timer()
    
    var numOfCoordsForNextInstruction = 0
    
    //In miles
    public var totalDistance = 0.0
    //In seconds
    public var totalTime = 0
    //Minutes per mile
    public var totalPace = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        statsOverlayView.layer.cornerRadius = 32.0
        //statsOverlayView.clipsToBounds = true
        
        statsOverlayView.layer.shadowColor = UIColor.black.cgColor
        statsOverlayView.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        statsOverlayView.layer.shadowRadius = 2
        statsOverlayView.layer.shadowOpacity = 0.5
        
        findARouteButton.layer.shadowColor = UIColor.black.cgColor
        findARouteButton.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        findARouteButton.layer.shadowRadius = 2
        findARouteButton.layer.shadowOpacity = 0.5
        
        beginRunButton.layer.shadowColor = UIColor.black.cgColor
        beginRunButton.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        beginRunButton.layer.shadowRadius = 2
        beginRunButton.layer.shadowOpacity = 0.5
        
        pauseRunButton.layer.shadowColor = UIColor.black.cgColor
        pauseRunButton.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        pauseRunButton.layer.shadowRadius = 2
        pauseRunButton.layer.shadowOpacity = 0.5
        
        finishRunButton.layer.shadowColor = UIColor.black.cgColor
        finishRunButton.layer.shadowOffset = CGSize.init(width: 2, height: 2)
        finishRunButton.layer.shadowRadius = 2
        finishRunButton.layer.shadowOpacity = 0.5
        
        finishRunButton.isHidden = true
        pauseRunButton.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("View appear")
        print(loadedRouteCoords)
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
            
            let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
            
            for coord in loadedRouteCoords {
                print("Coordinate: Lat: \(coord.latitude), Long: \(coord.longitude)")
            }
        }
        
        if (loadedRouteInstructions != nil) {
            for instruction in loadedRouteInstructions {
                print("Instruction: \(instruction.text)")
            }
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
        previousLocation = currentLocation
        currentLocation = locations.last! as CLLocation!
        if (previousLocation != nil && currentLocation != nil && paused == false) {
            //\currentLocation.hor
            let changeInDistance = currentLocation.distance(from: previousLocation)
            totalDistance += metersToMiles(meters: changeInDistance)
            distanceLabel.text = String(format: "%.2f", roundToTwoDecimals(double: totalDistance))
            //distanceLabel.text = "\(roundToTwoDecimals(double: totalDistance))"
            
            if (totalDistance > 0.1) {
                totalPace = Double(totalTime)/totalDistance
                let minutes = secondsToMinuteDigit(seconds: Int(totalPace))
                let seconds = secondsToSecondsDigits(seconds: Int(totalPace))
                paceMinutesLabel.text = "\(minutes)"
                if (seconds < 10) {
                    paceSecondsLabel.text = "0\(seconds)"
                }
                else {
                    paceSecondsLabel.text = "\(seconds)"
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("error:: (error)")
    }
    
    func currentLatitude() -> CLLocationDegrees {
        return currentLocation.coordinate.latitude
    }
    
    func currentLongitude() -> CLLocationDegrees {
        return currentLocation.coordinate.longitude
    }
    
    func milesToMeters(miles: Double) -> Int {
        return Int(miles*1609.344)
    }
    
    func metersToMiles(meters: Double) -> Double {
        return meters/1609.344
    }
    
    func millisecondsToMinutes(milliseconds: Int) -> Double {
        return Double(milliseconds*60)/3600000.0
    }
    
    func secondsToMinuteDigit(seconds: Int) -> Int {
        return seconds/60
    }
    
    func secondsToSecondsDigits(seconds: Int) -> Int {
        return seconds%60
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    func setRouteLoaded() {
        findARouteButton.setTitle("Modify Route", for: .normal)
    }
    
    @IBAction func beginRun(_ sender: UIButton) {
        beginRunButton.isHidden = true
        findARouteButton.isHidden = true
        finishRunButton.isHidden = false
        pauseRunButton.isHidden = false
        
        paused = false
        
        statsOverlayBottomConstraint.constant += 170
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        if (loadedRouteInstructions != nil) {
            voiceGuidance()
        }

        timeUpdater()
        
    }

    func voiceGuidance() {
        let currentInstruction = loadedRouteInstructions.first!
        var instructionFormatted = ""
        if (currentInstruction.text == "Continue") {
            instructionFormatted = "\(currentInstruction.text) for \(roundToTwoDecimals(double: metersToMiles(meters: currentInstruction.distance))) miles"
        }
        else {
            instructionFormatted = "In \(roundToTwoDecimals(double: metersToMiles(meters: currentInstruction.distance))) miles, \(currentInstruction.text)"
        }
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: instructionFormatted)
        
        utterance.rate = 0.5
        
        synthesizer.speak(utterance)
        
        numOfCoordsForNextInstruction = currentInstruction.interval[1] - currentInstruction.interval[0] + 1
    }
    
    func timeUpdater() {
        timeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounting(){
        totalTime += 1;
        let minutes = secondsToMinuteDigit(seconds: totalTime)
        let seconds = secondsToSecondsDigits(seconds: totalTime)
        timeMinutesLabel.text = "\(minutes)"
        if (seconds < 10) {
            timeSecondsLabel.text = "0\(seconds)"
        }
        else {
            timeSecondsLabel.text = "\(seconds)"
        }
        
        /*print("Curr Lat: \(currentLocation.coordinate.latitude), Curr Long: \(currentLocation.coordinate.longitude)")
        print("LatDiff: \(abs(loadedRouteCoords.first!.latitude - currentLocation.coordinate.latitude))")
        print("LongDiff: \(abs(loadedRouteCoords.first!.longitude - currentLocation.coordinate.longitude))")
        print("CoordsLeft: \(numOfCoordsForNextInstruction)")*/
        if (loadedRouteCoords != nil) {
            if (abs(loadedRouteCoords.first!.latitude - currentLocation.coordinate.latitude) < 0.001 && abs(loadedRouteCoords.first!.longitude - currentLocation.coordinate.longitude) < 0.001) {
                loadedRouteCoords.removeFirst()
                print("Removed")
                numOfCoordsForNextInstruction -= 1
            }
            
            //Call next instruction if finished with previous one
            if (loadedRouteInstructions != nil && numOfCoordsForNextInstruction == 0) {
                loadedRouteInstructions.removeFirst()
                voiceGuidance()
            }
        }
    }
    
    @IBAction func findARoute(_ sender: UIButton) {
        
    }
    
    @IBAction func finishRun(_ sender: UIButton) {
        beginRunButton.isHidden = false
        findARouteButton.isHidden = false
        finishRunButton.isHidden = true
        pauseRunButton.isHidden = true
        
        statsOverlayBottomConstraint.constant -= 170
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        timeTimer.invalidate()
        
        saveRun()
        
        totalDistance = 0
        totalTime = 0
        totalPace = 0
        
    }
    
    @IBAction func pauseRun(_ sender: UIButton) {
        if (paused == false) {
            //Pause run
            pauseRunButton.setTitle("Resume Run", for: .normal)
            timeTimer.invalidate()
            paused = true
        }
        else {
            //Resume run
            pauseRunButton.setTitle("Pause Run", for: .normal)
            timeUpdater()
            paused = false
        }
    }
    
    // MARK: - showRouteOnMap
    
    /*func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .walking
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }*/
    
    // MARK: - MKMapViewDelegate
    
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
    
    func saveRun() {
        let userId = AccessToken.current?.userID
        let timestamp = NSDate().timeIntervalSince1970
        let db = Firestore.firestore()
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        ref = db.collection("users").document(userId!).collection("runs").addDocument(data: [
            "timestamp": timestamp,
            "distance": totalDistance,
            "time": totalTime,
            "pace": totalPace
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    func decodeTimestamp(timestamp: TimeInterval) {
        let myTimeInterval = TimeInterval(timestamp)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
    }
}
