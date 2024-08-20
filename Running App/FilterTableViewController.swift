//
//  FilterTableViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/25/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import CoreLocation

class FilterTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var isRowHidden: [Bool] = [false, false, true, false, false, false, false, false]
    @IBOutlet weak var roundTripSwitchValue: UISwitch!
    @IBAction func roundTripSwitch(_ sender: UISwitch) {
        if (sender.isOn) {
            //Starting Point
            isRowHidden[1] = false
            //Ending Point
            isRowHidden[2] = true
            //Distance
            isRowHidden[3] = false
            
            /*UIView.animate(withDuration: 0.25, animations: {
                self.filterRoutesView.frame = CGRect(x: 0, y: 0, width: self.filterRoutesView.frame.width, height: self.filterRoutesView.frame.height + 44.0)
            })*/

            tableView.beginUpdates()
            tableView.endUpdates()
        }
        else {
            //Starting Point
            isRowHidden[1] = false
            //Ending Point
            isRowHidden[2] = false
            //Distance
            isRowHidden[3] = true
            
            /*UIView.animate(withDuration: 0.25, animations: {
                self.filterRoutesView.frame = CGRect(x: 0, y: 0, width: self.filterRoutesView.frame.width, height: self.filterRoutesView.frame.height - 44.0)
            })*/

            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    @IBOutlet weak var distanceCell: UITableViewCell!
    @IBOutlet weak var startingPointCell: UITableViewCell!
    @IBOutlet weak var endingPointCell: UITableViewCell!
    
    @IBOutlet weak var distanceText: UITextField!
    @IBOutlet weak var startingPointText: UITextField!
    @IBOutlet weak var endingPointText: UITextField!
    
    @IBOutlet weak var filterRoutesView: UIView!
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //let pickerData = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    
    let pickerFirstSecond = [["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30"],["0","1","2","3","4","5","6","7","8","9"]];
    
    public var startingLocation: CLLocationCoordinate2D!

    public var endingLocation: CLLocationCoordinate2D!

    /*func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        distanceText.text = pickerData[row]
    }*/
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerFirstSecond[component].count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerFirstSecond[component][row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let first = pickerFirstSecond[0][pickerView.selectedRow(inComponent: 0)]
        let second = pickerFirstSecond[1][pickerView.selectedRow(inComponent: 1)]
        distanceText.text = first + "." + second + " miles"
        
    }
    
    @objc func donePicker() {
        
        distanceText.resignFirstResponder()
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Starting Point
        if (indexPath.item == 1) {
            performSegue(withIdentifier: "popupMap", sender: true)
        }
        //Ending Point
        if (indexPath.item == 2) {
            performSegue(withIdentifier: "popupMap", sender: false)
        }
        //Distance
        if (indexPath.item == 3) {
            let position = distanceText.position(from: distanceText.endOfDocument, offset: 0)
            
            distanceText.selectAll(nil)
            
            distanceText.selectedTextRange = distanceText.textRange(from: position!, to: position!)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var height = 0.0
        
        if (isRowHidden[indexPath.row]) {
            height = 0.0
        } else {
            height = 44.0
        }
        return CGFloat.init(height)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is MapSelectViewController
        {
            let vc = segue.destination as? MapSelectViewController
            let starting = sender as! Bool
            vc?.starting = starting
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        let picker: UIPickerView
        let frame = CGRect.init(x: 0, y: 200, width: view.frame.width, height: 300)
        picker = UIPickerView(frame: frame)
        picker.backgroundColor = .white
        
        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(donePicker))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        distanceText.inputView = picker
        distanceText.inputAccessoryView = toolBar
        
        let presenter = self.presentingViewController as! TabBarController
        let presenterChild = presenter.viewControllers![1] as! RunTabController
        startingLocation = presenterChild.currentLocation.coordinate
        endingLocation = presenterChild.currentLocation.coordinate
        
        lookUpLocations()
    }
    
    func lookUpLocations() {
        let startLocation = CLLocation.init(latitude: startingLocation.latitude, longitude: startingLocation.longitude)
        let startGeocoder = CLGeocoder()
        // Look up the location and pass it to the completion handler
        startGeocoder.reverseGeocodeLocation(startLocation,
            completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    self.startingPointText.text = firstLocation?.thoroughfare
                }
                else {
                    // An error occurred during geocoding.
                }
        })
        
        let endLocation = CLLocation.init(latitude: endingLocation.latitude, longitude: endingLocation.longitude)
        let endGeocoder = CLGeocoder()
        // Look up the location and pass it to the completion handler
        endGeocoder.reverseGeocodeLocation(endLocation,
            completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    self.endingPointText.text = firstLocation?.thoroughfare
                }
                else {
                    // An error occurred during geocoding.
                }
        })
    }
    
}

