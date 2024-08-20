//
//  FeedTabController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/15/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FacebookCore
import FacebookLogin

class RunObject {
    var name: String!
    var timestamp: TimeInterval!
    var distance: Double!
    var time: Int!
    var pace: Double!
    var profilePictureURL: URL!
}

class RunTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeMinutesLabel: UILabel!
    @IBOutlet weak var timeSecondsLabel: UILabel!
    @IBOutlet weak var paceMinutesLabel: UILabel!
    @IBOutlet weak var paceSecondsLabel: UILabel!
    
    @IBOutlet weak var loadingSpinnerView: UIActivityIndicatorView!
    
    @IBOutlet weak var dimOverlayView: UIView!
    
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
    
    func secondsToMinuteDigit(seconds: Int) -> Int {
        return seconds/60
    }
    
    func secondsToSecondsDigits(seconds: Int) -> Int {
        return seconds%60
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.profilePictureView.image = UIImage(data: data)
                //Circle crop profile picture
                self.profilePictureView.layer.cornerRadius = self.profilePictureView.frame.size.width / 2
                self.profilePictureView.clipsToBounds = true
                
                self.loadingSpinnerView.stopAnimating()
                
                self.dimOverlayView.isHidden = true
            }
        }
    }
    
    override func prepareForReuse() {
        distanceLabel.text = "0.00"
        timeMinutesLabel.text = "0"
        timeSecondsLabel.text = "00"
        paceMinutesLabel.text = "0"
        paceSecondsLabel.text = "00"
        profilePictureView.image = nil
    }
    
    func decodeTimestamp(timestamp: TimeInterval) -> String {
        let myTimeInterval = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: TimeInterval(myTimeInterval))
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
        let formattedDate = "\(calendarDate.month!)/\(calendarDate.day!)/\(calendarDate.year!)"
        return formattedDate
    }
    
    func showRun(run: RunObject) {
        nameLabel.text = run.name
        dateLabel.text = decodeTimestamp(timestamp: run.timestamp)
        distanceLabel.text = String(format: "%.2f", roundToTwoDecimals(double: run.distance))
        let minutes = secondsToMinuteDigit(seconds: run.time)
        let seconds = secondsToSecondsDigits(seconds: run.time)
        timeMinutesLabel.text = "\(minutes)"
        if (seconds < 10) {
            timeSecondsLabel.text = "0\(seconds)"
        }
        else {
            timeSecondsLabel.text = "\(seconds)"
        }
        let paceMinutes = secondsToMinuteDigit(seconds: Int(run.pace))
        let paceSeconds = secondsToSecondsDigits(seconds: Int(run.pace))
        paceMinutesLabel.text = "\(paceMinutes)"
        if (paceSeconds < 10) {
            paceSecondsLabel.text = "0\(paceSeconds)"
        }
        else {
            paceSecondsLabel.text = "\(paceSeconds)"
        }
        
        downloadImage(from: run.profilePictureURL)
    }
    
}

class FeedTabController: UITableViewController {
    
    var runs = [RunObject]()
    
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
        return runs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "runTableViewCell", for: indexPath)
            as! RunTableViewCell
        
        cell.tag = indexPath.row
        
        cell.isUserInteractionEnabled = false
        
        cell.distanceLabel.text = "0.00"
        cell.timeMinutesLabel.text = "0"
        cell.timeSecondsLabel.text = "00"
        cell.paceMinutesLabel.text = "0"
        cell.paceSecondsLabel.text = "00"
        cell.profilePictureView.image = nil
        
        cell.dimOverlayView.isHidden = false

        cell.loadingSpinnerView.startAnimating()
        
        //Set cell data here
        if (indexPath.row < runs.count) {
            if cell.tag == indexPath.row {
                cell.showRun(run: runs[indexPath.row])
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.rowHeight = 140;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getRuns()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.runs.removeAll()
        self.tableView.reloadData()
    }

    func getRuns() {
        guard AccessToken.current != nil else {
            self.tableView.reloadData()
            return
        }
        //Friends' runs
        let request = GraphRequest(graphPath: "me/friends", parameters: [:])
        request.start() { connection, result, error in
            if let result = result as? [String: Any], error == nil {
                print("fetched user: \(result)")
                let friendsArray = result["data"] as! NSArray
                print("Friends are: \(friendsArray)")
                for friend in friendsArray {
                    let userId = (friend as! Dictionary<String, String>)["id"]!
                    let request = GraphRequest(graphPath: userId, parameters: [:])
                    request.start() { connection, result, error in
                        if let result = result, error == nil {
                            //We have accessed the friend's UserProfile object
                            //let userId = result.userId
                            let timestamp = NSDate().timeIntervalSince1970
                            let db = Firestore.firestore()
                            // Add a new document with a generated ID
                            var ref: DocumentReference? = nil
                            db.collection("users").document(userId).collection("runs").order(by: "timestamp", descending: true).getDocuments() { (querySnapshot, err) in
                                if let err = err {
                                    print("Error getting documents: \(err)")
                                } else {
                                    for document in querySnapshot!.documents {
                                        print("\(document.documentID) => \(document.data())")
                                        let newRun = RunObject()
                                        newRun.name = MyDataStore.user.first_name as! String
                                        newRun.timestamp = document.get("timestamp") as! TimeInterval
                                        newRun.distance = document.get("distance") as! Double
                                        newRun.time = document.get("time") as! Int
                                        newRun.pace = document.get("pace") as! Double
                                        newRun.profilePictureURL = URL(string: MyDataStore.user.picture.data.url as! String)
                                        self.runs.append(newRun)
                                        self.runs.sort(by: { (RunObject1, RunObject2) -> Bool in
                                            if (RunObject1.timestamp > RunObject2.timestamp) {
                                                return true
                                            }
                                            else {
                                                return false
                                            }
                                        })
                                    }
                                    self.tableView.reloadData()
                                }
                            }
                        }
                        else
                        {
                            print("Error getting friend: \(error)")
                        }
                    }
                }
            }
            else
            {
                print("Graph Request Failed: \(error)")
            }
        }
        
        //Your runs
        let userId = AccessToken.current?.userID
        let timestamp = NSDate().timeIntervalSince1970
        let db = Firestore.firestore()
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        db.collection("users").document(userId!).collection("runs").order(by: "timestamp", descending: true).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    let newRun = RunObject()
                    newRun.name = MyDataStore.user.first_name as! String
                    newRun.timestamp = document.get("timestamp") as! TimeInterval
                    newRun.distance = document.get("distance") as! Double
                    newRun.time = document.get("time") as! Int
                    newRun.pace = document.get("pace") as! Double
                    newRun.profilePictureURL = URL(string: MyDataStore.user.picture.data.url as! String)
                    self.runs.append(newRun)
                    self.runs.sort(by: { (RunObject1, RunObject2) -> Bool in
                        if (RunObject1.timestamp > RunObject2.timestamp) {
                            return true
                        }
                        else {
                            return false
                        }
                    })
                    self.tableView.reloadData()
                }
            }
        }

    }
    
}
