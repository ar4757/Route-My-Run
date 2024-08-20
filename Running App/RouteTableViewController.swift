//
//  RouteTableViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/26/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GraphHopperRouting

class RouteObject {
    var coords: [CLLocationCoordinate2D]!
    var polyline: MKPolyline!
    var distance: Double!
    var up: Double!
    var down: Double!
    var region: MKCoordinateRegion!
    var instructions: [Instruction]!
}

class RouteTableViewCell: UITableViewCell, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var loadingSpinnerView: UIActivityIndicatorView!
    
    @IBOutlet weak var dimOverlayView: UIView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var upLabel: UILabel!
    @IBOutlet weak var downLabel: UILabel!
    @IBOutlet weak var upImage: UIImageView!
    @IBOutlet weak var downImage: UIImageView!
    
    var currentLocation: CLLocation!
    
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
    
    func metersToFeet(meters: Double) -> Double {
        return meters*3.28084
    }
    
    func millisecondsToMinutes(milliseconds: Int) -> Double {
        return Double(milliseconds*60)/3600000.0
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    override func prepareForReuse() {
        mapView.removeOverlays(mapView.overlays)
        distanceLabel.text = ""
        upLabel.text = ""
        downLabel.text = ""
        upImage.isHidden = true
        downImage.isHidden = true
    }
    
    
    func plotRoute(route: RouteObject) {
        self.mapView.addOverlay(route.polyline)
        self.distanceLabel.text = "\(route.distance!) miles"
        self.upLabel.text = "\(route.up!) ft"
        self.downLabel.text = "\(route.down!) ft"
        self.upImage.isHidden = false
        self.downImage.isHidden = false

        self.mapView.setRegion(route.region, animated: false)
        self.loadingSpinnerView.stopAnimating()
        
        self.dimOverlayView.isHidden = true
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
}

class RouteTableViewController: UITableViewController {
    
    var distance: Double!
    var startingLocation: CLLocationCoordinate2D!
    var endingLocation: CLLocationCoordinate2D!
    var currentLocation: CLLocation!
    
    let numOfRoutes = 1
    
    var coords: [CLLocationCoordinate2D]!
    
    var routes = [RouteObject]()
    
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
    
    func metersToFeet(meters: Double) -> Double {
        return meters*3.28084
    }
    
    func millisecondsToMinutes(milliseconds: Int) -> Double {
        return Double(milliseconds*60)/3600000.0
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (routes.count == 0) {
            return 50
        }
        else {
            return routes.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeTableViewCell", for: indexPath)
            as! RouteTableViewCell
        
        cell.mapView.delegate = cell
        
        cell.distanceLabel.text = ""
        cell.upLabel.text = ""
        cell.downLabel.text = ""
        cell.upImage.isHidden = true
        cell.downImage.isHidden = true
        cell.mapView.isUserInteractionEnabled = false

        //Set cell data here
        if (indexPath.row < routes.count) {
            cell.plotRoute(route: routes[indexPath.row])
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "popupRouteConfirmation", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is RouteConfirmationViewController
        {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let vc = segue.destination as! RouteConfirmationViewController
                vc.loadedRouteCoords = routes[indexPath.row].coords
                vc.loadedRouteInstructions = routes[indexPath.row].instructions
                vc.startingLocation = startingLocation
                vc.endingLocation = endingLocation
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.rowHeight = 140;
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let presenter = self.parent?.children.first as! FilterTableViewController
        let parsed = presenter.distanceText.text!.replacingOccurrences(of: " miles", with: "")
        distance = Double(parsed)
        startingLocation = presenter.startingLocation
        endingLocation = presenter.endingLocation

        let presentersPresenter = presenter.presentingViewController as! TabBarController
        let runTabController = presentersPresenter.viewControllers![1] as! RunTabController
        currentLocation = runTabController.currentLocation

        if (currentLocation != nil && distance != nil && startingLocation != nil && endingLocation != nil) {
            getRoutes(numOfRoutes: numOfRoutes)
        }
    }
    
    func getRoutes(numOfRoutes: Int) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) { [weak self] in
            self?.routes.sort {
                $0.distance < $1.distance
            }
            self?.tableView.reloadData()
        }
        let routing = Routing(accessToken: "604fac72-b9f2-47e0-bb70-7eaf1984dfae")
        //Round Trip
        if (startingLocation.latitude == endingLocation.latitude && startingLocation.longitude == endingLocation.longitude) {
            let points = [startingLocation]
            let options = FlexibleRouteOptions(points: points as! [CLLocationCoordinate2D])
            //options.weighting = .shortest
            //distance in meters
            options.vehicle = .foot
            for i in 1...numOfRoutes {
                print("Iteration: \(i)")
                options.algorithm = .roundTrip(distance: milesToMeters(miles: distance), seed: i)
                //options.heading = [60.0]
                //options.headingPenalty = 1
                calcRoundTripRoute(routing: routing, options: options, seed: i)
            }
        }
        //Not Round Trip
        else {
            let points = [startingLocation, endingLocation]
            let options = FlexibleRouteOptions(points: points as! [CLLocationCoordinate2D])
            options.vehicle = .foot
            options.algorithm = .alternativeRoute(maxPaths: 50, maxWeightFactor: 10.0, maxShareFactor: 10.0)
            for i in 1...numOfRoutes {
                calcStartEndRoute(routing: routing, options: options, seed: i)
            }
        }
    }
    
    func calcRoundTripRoute(routing: Routing, options: FlexibleRouteOptions, seed: Int) {
        let task = routing.calculate(options, completionHandler: { (paths, error) in
            print("Error: \(error)")
            paths?.forEach({ path in
                print("Time: \(self.millisecondsToMinutes(milliseconds: path.time)) minutes")
                print("Distance: \(self.metersToMiles(meters: path.distance)) miles")
                //print(path.time)
                //print(path.distance)
                print(path.descend)
                print(path.ascend)
                print("Instructions: \(path.instructions.count)")
                print("Points: \(path.points.count)")
                path.instructions.forEach({ instruction in
                    print(instruction.streetName)
                })
                self.coords = path.points.map {
                    $0.coordinate
                }
                let coords = self.coords
                let myPolyline = MKPolyline(coordinates: self.coords, count: self.coords.count)
                
                let distanceDouble = self.roundToTwoDecimals(double: self.metersToMiles(meters: path.distance))
                let upDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path.ascend))
                let downDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path.descend))
                
                let longitudeDiff = abs(Double(path.bbox!.topLeft.longitude) - Double(path.bbox!.bottomRight.longitude))
                let latitudeDiff = abs(Double(path.bbox!.topLeft.latitude) - Double(path.bbox!.bottomRight.latitude))
                let span = MKCoordinateSpan(latitudeDelta: latitudeDiff*5, longitudeDelta: longitudeDiff*5)
                let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
                
                let instructions = path.instructions
                
                let newRoute = RouteObject()
                newRoute.coords = coords
                newRoute.polyline = myPolyline
                newRoute.distance = distanceDouble
                newRoute.up = upDouble
                newRoute.down = downDouble
                newRoute.region = region
                newRoute.instructions = instructions
                
                let optionsParams = options.algorithm.asParams()
                let desiredDistanceInMeters = Double(optionsParams[1].value!)
                let desiredDistanceDouble = self.roundToTwoDecimals(double: self.metersToMiles(meters: desiredDistanceInMeters!))
                
                //Route must be within 5% of desired distance
                //if ((distanceDouble / desiredDistanceDouble >= 0.95) && (distanceDouble / desiredDistanceDouble //<= 1.0) || (distanceDouble / desiredDistanceDouble <= 1.05) && (distanceDouble / //desiredDistanceDouble >= 1.0)) {
                //    self.routes.append(newRoute)
                //}
                self.routes.append(newRoute)
                print("Route count: \(self.routes.count)")
            })
        })
    }
    
    func calcStartEndRoute(routing: Routing, options: FlexibleRouteOptions, seed: Int) {
        let task = routing.calculate(options, completionHandler: { (paths, error) in
            print("Error: \(error)")
            paths?.forEach({ path in
                print("Time: \(self.millisecondsToMinutes(milliseconds: path.time)) minutes")
                print("Distance: \(self.metersToMiles(meters: path.distance)) miles")
                //print(path.time)
                //print(path.distance)
                print(path.descend)
                print(path.ascend)
                print("Instructions: \(path.instructions.count)")
                print("Points: \(path.points.count)")
                path.instructions.forEach({ instruction in
                    print(instruction.streetName)
                })
                self.coords = path.points.map {
                    $0.coordinate
                }
                let coords = self.coords
                let myPolyline = MKPolyline(coordinates: self.coords, count: self.coords.count)
                
                let distanceDouble = self.roundToTwoDecimals(double: self.metersToMiles(meters: path.distance))
                let upDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path.ascend))
                let downDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path.descend))
                
                let longitudeDiff = abs(Double(path.bbox!.topLeft.longitude) - Double(path.bbox!.bottomRight.longitude))
                let latitudeDiff = abs(Double(path.bbox!.topLeft.latitude) - Double(path.bbox!.bottomRight.latitude))
                let span = MKCoordinateSpan(latitudeDelta: longitudeDiff, longitudeDelta: latitudeDiff)
                let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
                
                let instructions = path.instructions
                
                let newRoute = RouteObject()
                newRoute.coords = coords
                newRoute.polyline = myPolyline
                newRoute.distance = distanceDouble
                newRoute.up = upDouble
                newRoute.down = downDouble
                newRoute.region = region
                newRoute.instructions = instructions
                
                self.routes.append(newRoute)
                print("Route count: \(self.routes.count)")
            })
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
}

/*func showRoutes() {
 let routing = Routing(accessToken: "59aa616f-2507-4267-8eff-860df740a1ba")
 let points = [
 CLLocationCoordinate2D(latitude: Double(currentLatitude()), longitude: Double(currentLongitude()))
 ]
 //let options = RouteOptions(points: points)
 //options.elevation = true
 //options.instructions = true
 //options.locale = "de-DE"
 //options.vehicle = .foot
 //options.optimize = true
 let options = FlexibleRouteOptions(points: points)
 //options.weighting = .shortest
 //distance in meters
 options.vehicle = .foot
 options.algorithm = .roundTrip(distance: milesToMeters(miles: distance), seed: 0)
 
 let task = routing.calculate(options, completionHandler: { (paths, error) in
 paths?.forEach({ path in
 print("Time: \(self.millisecondsToMinutes(milliseconds: path.time)) minutes")
 print("Distance: \(self.metersToMiles(meters: path.distance)) miles")
 //print(path.time)
 //print(path.distance)
 print(path.descend)
 print(path.ascend)
 print("Instructions: \(path.instructions.count)")
 print("Points: \(path.points.count)")
 path.instructions.forEach({ instruction in
 print(instruction.streetName)
 })
 let coords = path.points.map {
 $0.coordinate
 }
 let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
 
 self.mapView.addOverlay(myPolyline)
 
 let longitudeDiff = abs(Double(path.bbox!.topLeft.longitude) - Double(path.bbox!.bottomRight.longitude))
 let latitudeDiff = abs(Double(path.bbox!.topLeft.latitude) - Double(path.bbox!.bottomRight.latitude))
 let span = MKCoordinateSpan(latitudeDelta: longitudeDiff, longitudeDelta: latitudeDiff)
 let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
 self.mapView.setRegion(region, animated: true)
 
 })
 })
 }*/




/*
//
//  RouteTableViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/26/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GraphHopperRouting

class RouteTableViewCell: UITableViewCell, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var loadingSpinnerView: UIActivityIndicatorView!
    
    @IBOutlet weak var dimOverlayView: UIView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var upLabel: UILabel!
    @IBOutlet weak var downLabel: UILabel!
    @IBOutlet weak var upImage: UIImageView!
    @IBOutlet weak var downImage: UIImageView!
    
    var currentLocation: CLLocation!
    
    var coords: [CLLocationCoordinate2D]!
    
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
    
    func metersToFeet(meters: Double) -> Double {
        return meters*3.28084
    }
    
    func millisecondsToMinutes(milliseconds: Int) -> Double {
        return Double(milliseconds*60)/3600000.0
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    override func prepareForReuse() {
        mapView.removeOverlays(mapView.overlays)
        distanceLabel.text = ""
        upLabel.text = ""
        downLabel.text = ""
        upImage.isHidden = true
        downImage.isHidden = true
    }
    
    func getRoute(currentLocation: CLLocation, startingLocation: CLLocationCoordinate2D, endingLocation: CLLocationCoordinate2D, distance: Double, seed: Int) {
        self.currentLocation = currentLocation
        self.dimOverlayView.isHidden = false
        self.loadingSpinnerView.startAnimating()
        //let routing = Routing(accessToken: "59aa616f-2507-4267-8eff-860df740a1ba")
        let routing = Routing(accessToken: "b6cc1c85-58b8-4d7c-8d51-16d3130ceb7f")
        //Round Trip
        if (startingLocation.latitude == endingLocation.latitude && startingLocation.longitude == endingLocation.longitude) {
            let points = [startingLocation]
            let options = FlexibleRouteOptions(points: points)
            //options.weighting = .shortest
            //distance in meters
            options.vehicle = .foot
            options.algorithm = .roundTrip(distance: milesToMeters(miles: distance), seed: seed)
            //options.heading = [60.0]
            //options.headingPenalty = 1
            plotRoundTripRoute(routing: routing, options: options)
        }
            //Not Round Trip
        else {
            let points = [startingLocation, endingLocation]
            let options = FlexibleRouteOptions(points: points)
            options.vehicle = .foot
            options.algorithm = .alternativeRoute(maxPaths: 10, maxWeightFactor: 10.0, maxShareFactor: 10.0)
            options.elevation = true
            plotStartEndRoute(routing: routing, options: options, seed: seed)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
    func plotRoundTripRoute(routing: Routing, options: RouteOptions) {
        let task = routing.calculate(options, completionHandler: { (paths, error) in
            paths?.forEach({ path in
                print("Time: \(self.millisecondsToMinutes(milliseconds: path.time)) minutes")
                print("Distance: \(self.metersToMiles(meters: path.distance)) miles")
                //print(path.time)
                //print(path.distance)
                print(path.descend)
                print(path.ascend)
                print("Instructions: \(path.instructions.count)")
                print("Points: \(path.points.count)")
                path.instructions.forEach({ instruction in
                    print(instruction.streetName)
                })
                self.coords = path.points.map {
                    $0.coordinate
                }
                
                let myPolyline = MKPolyline(coordinates: self.coords, count: self.coords.count)
                
                self.mapView.addOverlay(myPolyline)
                let distanceDouble = self.roundToTwoDecimals(double: self.metersToMiles(meters: path.distance))
                let upDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path.ascend))
                let downDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path.descend))
                self.distanceLabel.text = "\(distanceDouble) miles"
                self.upLabel.text = "\(upDouble) ft"
                self.downLabel.text = "\(downDouble) ft"
                self.upImage.isHidden = false
                self.downImage.isHidden = false
                
                let longitudeDiff = abs(Double(path.bbox!.topLeft.longitude) - Double(path.bbox!.bottomRight.longitude))
                let latitudeDiff = abs(Double(path.bbox!.topLeft.latitude) - Double(path.bbox!.bottomRight.latitude))
                let span = MKCoordinateSpan(latitudeDelta: latitudeDiff*5, longitudeDelta: longitudeDiff*5)
                let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
                self.mapView.setRegion(region, animated: false)
                self.loadingSpinnerView.stopAnimating()
                
                self.dimOverlayView.isHidden = true
            })
        })
    }
    
    func plotStartEndRoute(routing: Routing, options: RouteOptions, seed: Int) {
        let task = routing.calculate(options, completionHandler: { (paths, error) in
            var path: RoutePath?
            if (seed < paths!.count) {
                path = paths![seed]
            }
            if (path != nil) {
                print("Time: \(self.millisecondsToMinutes(milliseconds: path!.time)) minutes")
                print("Distance: \(self.metersToMiles(meters: path!.distance)) miles")
                //print(path.time)
                //print(path.distance)
                print(path!.descend)
                print(path!.ascend)
                print("Instructions: \(path!.instructions.count)")
                print("Points: \(path!.points.count)")
                path!.instructions.forEach({ instruction in
                    print(instruction.streetName)
                })
                self.coords = path!.points.map {
                    $0.coordinate
                }
                
                let myPolyline = MKPolyline(coordinates: self.coords, count: self.coords.count)
                
                self.mapView.addOverlay(myPolyline)
                let distanceDouble = self.roundToTwoDecimals(double: self.metersToMiles(meters: path!.distance))
                let upDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path!.ascend))
                let downDouble = self.roundToTwoDecimals(double: self.metersToFeet(meters: path!.descend))
                self.distanceLabel.text = "\(distanceDouble) miles"
                self.upLabel.text = "\(upDouble) ft"
                self.downLabel.text = "\(downDouble) ft"
                self.upImage.isHidden = false
                self.downImage.isHidden = false
                
                let longitudeDiff = abs(Double(path!.bbox!.topLeft.longitude) - Double(path!.bbox!.bottomRight.longitude))
                let latitudeDiff = abs(Double(path!.bbox!.topLeft.latitude) - Double(path!.bbox!.bottomRight.latitude))
                let span = MKCoordinateSpan(latitudeDelta: longitudeDiff, longitudeDelta: latitudeDiff)
                let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
                self.mapView.setRegion(region, animated: false)
                self.loadingSpinnerView.stopAnimating()
                
                self.dimOverlayView.isHidden = true
            }
        })
    }
    
}

class RouteTableViewController: UITableViewController {
    
    var distance: Double!
    var startingLocation: CLLocationCoordinate2D!
    var endingLocation: CLLocationCoordinate2D!
    var currentLocation: CLLocation!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeTableViewCell", for: indexPath)
            as! RouteTableViewCell
        
        cell.mapView.delegate = cell
        
        cell.distanceLabel.text = ""
        cell.upLabel.text = ""
        cell.downLabel.text = ""
        cell.upImage.isHidden = true
        cell.downImage.isHidden = true
        
        if (currentLocation != nil && distance != nil && startingLocation != nil && endingLocation != nil) {
            cell.getRoute(currentLocation: currentLocation, startingLocation: startingLocation, endingLocation: endingLocation, distance: distance, seed: indexPath.row)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let presenter = self.parent?.children.first as! FilterTableViewController
        let parsed = presenter.distanceText.text!.replacingOccurrences(of: " miles", with: "")
        distance = Double(parsed)
        
        let presentersPresenter = presenter.presentingViewController as! TabBarController
        let secondViewController = presentersPresenter.viewControllers![1] as! SecondViewController
        
        let selectedCell = tableView.cellForRow(at: indexPath) as! RouteTableViewCell
        secondViewController.loadedRouteCoords = selectedCell.coords
        secondViewController.mapView.removeOverlays(secondViewController.mapView.overlays)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.rowHeight = 140;
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let presenter = self.parent?.children.first as! FilterTableViewController
        let parsed = presenter.distanceText.text!.replacingOccurrences(of: " miles", with: "")
        distance = Double(parsed)
        startingLocation = presenter.startingLocation
        endingLocation = presenter.endingLocation
        
        let presentersPresenter = presenter.presentingViewController as! TabBarController
        let secondViewController = presentersPresenter.viewControllers![1] as! SecondViewController
        currentLocation = secondViewController.currentLocation
        
        self.tableView.reloadData()
    }
    
}

/*func showRoutes() {
 let routing = Routing(accessToken: "59aa616f-2507-4267-8eff-860df740a1ba")
 let points = [
 CLLocationCoordinate2D(latitude: Double(currentLatitude()), longitude: Double(currentLongitude()))
 ]
 //let options = RouteOptions(points: points)
 //options.elevation = true
 //options.instructions = true
 //options.locale = "de-DE"
 //options.vehicle = .foot
 //options.optimize = true
 let options = FlexibleRouteOptions(points: points)
 //options.weighting = .shortest
 //distance in meters
 options.vehicle = .foot
 options.algorithm = .roundTrip(distance: milesToMeters(miles: distance), seed: 0)
 
 let task = routing.calculate(options, completionHandler: { (paths, error) in
 paths?.forEach({ path in
 print("Time: \(self.millisecondsToMinutes(milliseconds: path.time)) minutes")
 print("Distance: \(self.metersToMiles(meters: path.distance)) miles")
 //print(path.time)
 //print(path.distance)
 print(path.descend)
 print(path.ascend)
 print("Instructions: \(path.instructions.count)")
 print("Points: \(path.points.count)")
 path.instructions.forEach({ instruction in
 print(instruction.streetName)
 })
 let coords = path.points.map {
 $0.coordinate
 }
 let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
 
 self.mapView.addOverlay(myPolyline)
 
 let longitudeDiff = abs(Double(path.bbox!.topLeft.longitude) - Double(path.bbox!.bottomRight.longitude))
 let latitudeDiff = abs(Double(path.bbox!.topLeft.latitude) - Double(path.bbox!.bottomRight.latitude))
 let span = MKCoordinateSpan(latitudeDelta: longitudeDiff, longitudeDelta: latitudeDiff)
 let region = MKCoordinateRegion(center: self.currentLocation.coordinate, span: span)
 self.mapView.setRegion(region, animated: true)
 
 })
 })
 }*/
*/
