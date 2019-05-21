//
//  ThirdViewController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/15/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin

/*class ThirdViewController: UIPageViewController {
    
    private var pageController: UIPageViewController?
    
    var bodyweight = 0
    
    /*@IBAction func changeTimeframe(_ sender: UISegmentedControl) {
        for subview in milesHorizontalStackView.subviews {
            milesHorizontalStackView.removeArrangedSubview(subview)
        }
        for subview in caloriesHorizontalStackView.subviews {
            caloriesHorizontalStackView.removeArrangedSubview(subview)
        }
        let selectedTimeFrame = sender.titleForSegment(at: sender.selectedSegmentIndex)
        if (selectedTimeFrame == "Month") {
            for i in 0...11 {
                if let barView = Bundle.main.loadNibNamed("BarView", owner: nil, options: nil)!.first as? BarView {
                    barView.translatesAutoresizingMaskIntoConstraints = false
                    barView.widthAnchor.constraint(equalToConstant: milesHorizontalStackView.frame.height).isActive = true
                    barView.timeframeLabel.text = months[i]
                    barView.valueLabel.text = String(format: "%.2f", roundToTwoDecimals(double: monthDictionary[monthIntToString(monthInt: i+1)]!))

                    milesHorizontalStackView.addArrangedSubview(barView)
                }
            }
            for i in 0...11 {
                if let barView = Bundle.main.loadNibNamed("BarView", owner: nil, options: nil)!.first as? BarView {
                    barView.translatesAutoresizingMaskIntoConstraints = false
                    barView.widthAnchor.constraint(equalToConstant: milesHorizontalStackView.frame.height).isActive = true
                    barView.timeframeLabel.text = months[i]
                    //Need to convert miles ran to calories
                    barView.valueLabel.text = String(format: "%.2f", roundToTwoDecimals(double: monthDictionary[monthIntToString(monthInt: i+1)]!)*0.72*Double(bodyweight))
                    
                    caloriesHorizontalStackView.addArrangedSubview(barView)
                }
            }
        }
        else if (selectedTimeFrame == "Day") {
            for i in 0...6 {
                if let barView = Bundle.main.loadNibNamed("BarView", owner: nil, options: nil)!.first as? BarView {
                    barView.translatesAutoresizingMaskIntoConstraints = false
                    barView.widthAnchor.constraint(equalToConstant: milesHorizontalStackView.frame.height).isActive = true
                    //barView.timeframeLabel.text = days[i]
                    milesHorizontalStackView.addArrangedSubview(barView)
                }
            }
        }
    }*/
    var runs = [RunObject]()
    var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    var dates = [String]()
    var monthDictionary: [String: Double]!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPageController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        monthDictionary = self.months.reduce(into: [:], { result, next in
            result[next] = 0.0 })
        // Iterate by 1 day
        // Feel free to change this variable to iterate by week, month etc.
        /*let dayDurationInSeconds = 60*60*24
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let startDate = formatter.date(from: "2019/01/01 12:00")!
        let endDate = Date()
        for date in stride(from: startDate, to: endDate, by: dayDurationInSeconds) {
            print(date)
        }*/
        //changeTimeframe(timeframeSelector)
        getBodyweight()
        //getRuns()
    }
    
    func getBodyweight() {
        //Async add to runs list
        let userId = UserProfile.current?.userId
        let db = Firestore.firestore()
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        
        db.collection("users").document(userId!).getDocument{ (document, error) in
            if let document = document, document.exists {
                if let bodyweight = document.get("bodyweight") {
                    self.bodyweight = bodyweight as! Int
                    //self.changeTimeframe(self.timeframeSelector)
                }
                else {
                    //User needs to input a bodyweight
                    let alert = UIAlertController(title: "What is your body weight?", message: "For calories to be calculated, we need to know your body weight (in pounds). This can be changed later in the Settings menu.", preferredStyle: .alert)
                    
                    alert.addTextField(configurationHandler: { textField in
                        textField.placeholder = "Input your body weight here..."
                    })
                    
                    alert.textFields?.first?.keyboardType = UIKeyboardType.numberPad
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        
                        if let bodyweight = alert.textFields?.first?.text {
                            self.bodyweight = Int(bodyweight)!
                            db.collection("users").document(userId!).setData([
                                "bodyweight": self.bodyweight
                                ])
                            
                            //self.changeTimeframe(self.timeframeSelector)
                        }
                    }))
                    
                    self.present(alert, animated: true)
                }
            } else {
                //User does not exist
                print("Document does not exist")
            }
        }
    }
    /*
    func getRuns() {
        //Async add to runs list
        let userId = UserProfile.current?.userId
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
                    newRun.name = UserProfile.current?.firstName
                    newRun.timestamp = document.get("timestamp") as! TimeInterval
                    newRun.distance = document.get("distance") as! Double
                    newRun.time = document.get("time") as! Int
                    newRun.pace = document.get("pace") as! Double
                    self.runs.append(newRun)
                }
                //After getting all runs
                //let selectedTimeframe = self.timeframeSelector.titleForSegment(at: self.timeframeSelector.selectedSegmentIndex)
                if (selectedTimeframe == "Month") {
                    for run in self.runs {
                        let monthOfRun = self.getMonthFromTimestamp(timestamp: run.timestamp)
                        self.monthDictionary[monthOfRun]! += run.distance!
                    }
                    //self.changeTimeframe(self.timeframeSelector)
                }
                else if (selectedTimeframe == "Day") {
                    for run in self.runs {
                        //let dateOfRun = self.getDateFromTimestamp(timestamp: run.timestamp)
                        //self.dateDictionary[dateOfRun]! += run.distance!
                    }
                    //self.changeTimeframe(self.timeframeSelector)
                }
            }
        }
    }
 */
    
    func getDateFromTimestamp(timestamp: TimeInterval) -> String {
        let myTimeInterval = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: TimeInterval(myTimeInterval))
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
        return "\(calendarDate.month)/\(calendarDate.day!)"
        return monthIntToString(monthInt: calendarDate.month!)
    }
    
    func getMonthFromTimestamp(timestamp: TimeInterval) -> String {
        let myTimeInterval = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: TimeInterval(myTimeInterval))
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
        return monthIntToString(monthInt: calendarDate.month!)
    }
    
    func monthIntToString(monthInt: Int) -> String {
        switch (monthInt) {
        case 1:
            return "January"
        case 2:
            return "February"
        case 3:
            return "March"
        case 4:
            return "April"
        case 5:
            return "May"
        case 6:
            return "June"
        case 7:
            return "July"
        case 8:
            return "August"
        case 9:
            return "September"
        case 10:
            return "October"
        case 11:
            return "November"
        case 12:
            return "December"
        default:
            return ""
        }
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    private func setupPageController() {
        self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageController?.dataSource = self
        self.pageController?.delegate = self
        self.pageController?.view.backgroundColor = .clear
        self.pageController?.view.frame = CGRect(x: 0,y: 0,width: self.view.frame.width,height: self.view.frame.height)
        self.addChild(self.pageController!)
        self.view.addSubview(self.pageController!.view)
        self.pageController?.didMove(toParent: self)
    }
}

extension ThirdViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return UIViewController()
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return UIViewController()
    }
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        //return self.lights.count
        return 3
    }
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        //return self.currentIndex
        return 0
    }
}

//
//  MyPageViewController.swift
//  Fusion Calculator
//
//  Created by Andrew Ratz on 3/28/18.
//  Copyright © 2018 Andrew Ratz. All rights reserved.
//

import UIKit
*/
class ThirdViewController: UIPageViewController {
    
    var currentIndex = 0
    
    var bodyweight = 0
    
    var pastWeekArray: [Date]!
    var pastWeekDurationDictionary: [Date: Int]!
    var pastWeekDistanceDictionary: [Date: Double]!
    var pastWeekCaloriesDictionary: [Date: Int]!
    
    var runs = [RunObject]()
    var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    var dates = [String]()
    var monthDictionary: [String: Double]!
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.createDurationViewController(pageNumber: 0), self.createDistanceViewController(pageNumber: 1), self.createCaloriesViewController(pageNumber: 2)]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        self.view.backgroundColor = UIColor.black
        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        appearance.pageIndicatorTintColor = UIColor.gray
        appearance.currentPageIndicatorTintColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
        
        self.view.backgroundColor = UIColor.white
        
        //var appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        //appearance.pageIndicatorTintColor = UIColor.red
        //appearance.currentPageIndicatorTintColor = UIColor.red
        
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
            //self.title = "Duration"
        }
        
        monthDictionary = self.months.reduce(into: [:], { result, next in
            result[next] = 0.0 })
        
        getPastWeek()
        // Iterate by 1 day
        // Feel free to change this variable to iterate by week, month etc.
        /*let dayDurationInSeconds = 60*60*24
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy/MM/dd HH:mm"
         let startDate = formatter.date(from: "2019/01/01 12:00")!
         let endDate = Date()
         for date in stride(from: startDate, to: endDate, by: dayDurationInSeconds) {
         print(date)
         }*/
        //changeTimeframe(timeframeSelector)
        /*for i in 0...6 {
            if let barView = Bundle.main.loadNibNamed("BarView", owner: nil, options: nil)!.first as? BarView {
                barView.translatesAutoresizingMaskIntoConstraints = false
                barView.widthAnchor.constraint(equalToConstant: view.frame.height).isActive = true
                barView.timeframeLabel.text = months[i]
                barView.valueLabel.text = String(format: "%.2f", roundToTwoDecimals(double: monthDictionary[monthIntToString(monthInt: i+1)]!))
                
                view.addSubview(barView)
            }
        }
         */
        getBodyweight()
        //getRuns()
        
    }
    
    override func viewDidLayoutSubviews() {
        for view in self.view.subviews {
            if view.isKind(of:UIScrollView.self) {
                view.frame = UIScreen.main.bounds
            } else if view.isKind(of:UIPageControl.self) {
                view.backgroundColor = UIColor.clear
            }
        }
        super.viewDidLayoutSubviews()
    }
    
    func createDurationViewController(pageNumber: Int) -> UIViewController {
        let contentViewController =
            storyboard?.instantiateViewController(withIdentifier: "DurationViewController")
                as! DurationViewController
        contentViewController.pageNumber = pageNumber
        return contentViewController
    }
    
    func createDistanceViewController(pageNumber: Int) -> UIViewController {
        let contentViewController =
            storyboard?.instantiateViewController(withIdentifier: "DistanceViewController")
                as! DistanceViewController
        contentViewController.pageNumber = pageNumber
        return contentViewController
    }
    
    func createCaloriesViewController(pageNumber: Int) -> UIViewController {
        let contentViewController =
            storyboard?.instantiateViewController(withIdentifier: "CaloriesViewController")
                as! CaloriesViewController
        contentViewController.pageNumber = pageNumber
        return contentViewController
    }
}

extension ThirdViewController: UIPageViewControllerDataSource {
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        currentIndex = previousIndex
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        currentIndex = nextIndex
        return orderedViewControllers[nextIndex]
    }
    
}

extension ThirdViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if (currentIndex == 0) {
                //self.title = "Duration"
            }
            else if (currentIndex == 1) {
                //self.title = "Distance"
            }
            else if (currentIndex == 2) {
                //self.title = "Calories"
            }
            updateGraphs()
        }
    }
    
}

extension ThirdViewController {
    func goToNextPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else {
            return
        }
        guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) else {
            return
        }
        setViewControllers([nextViewController], direction: .forward, animated: animated, completion: nil)
    }
    
    func goToPreviousPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else {
            return
        }
        guard let previousViewController = dataSource?.pageViewController(self, viewControllerBefore: currentViewController) else {
            return
        }
        setViewControllers([previousViewController], direction: .reverse, animated: animated, completion: nil)
        
    }
    
    func getBodyweight() {
        //Async add to runs list
        let userId = UserProfile.current?.userId
        let db = Firestore.firestore()
        // Add a new document with a generated ID
        var ref: DocumentReference? = nil
        
        db.collection("users").document(userId!).getDocument{ (document, error) in
            if let document = document, document.exists {
                if let bodyweight = document.get("bodyweight") {
                    self.bodyweight = bodyweight as! Int
                    print("Bodyweight: \(self.bodyweight)")
                    //self.changeTimeframe(self.timeframeSelector)
                    self.getRuns()
                }
                else {
                    //User needs to input a bodyweight
                    let alert = UIAlertController(title: "What is your body weight?", message: "For calories to be calculated, we need to know your body weight (in pounds). This can be changed later in the Settings menu.", preferredStyle: .alert)
                    
                    alert.addTextField(configurationHandler: { textField in
                        textField.placeholder = "Input your body weight here..."
                    })
                    
                    alert.textFields?.first?.keyboardType = UIKeyboardType.numberPad
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        
                        if let bodyweight = alert.textFields?.first?.text {
                            self.bodyweight = Int(bodyweight)!
                            db.collection("users").document(userId!).setData([
                                "bodyweight": self.bodyweight
                                ])
                            
                            //self.changeTimeframe(self.timeframeSelector)
                            self.getRuns()
                        }
                    }))
                    
                    self.present(alert, animated: true)
                }
            } else {
                //User does not exist
                print("Document does not exist")
            }
        }
    }
    
    func getRuns() {
        //Async add to runs list
        let userId = UserProfile.current?.userId
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
                    newRun.name = UserProfile.current?.firstName
                    newRun.timestamp = document.get("timestamp") as! TimeInterval
                    newRun.distance = document.get("distance") as! Double
                    newRun.time = document.get("time") as! Int
                    newRun.pace = document.get("pace") as! Double
                    self.runs.append(newRun)
                }
                //After getting all runs
                //let selectedTimeframe = self.timeframeSelector.titleForSegment(at: self.timeframeSelector.selectedSegmentIndex)
                let selectedTimeframe = "Week"
                if (selectedTimeframe == "Week") {
                    for run in self.runs {
                        print("Timestamp: \(run.timestamp!)")
                        let convertedTimestamp = NSDate(timeIntervalSince1970: run.timestamp!)
                        print("Timestamp 1970: \(convertedTimestamp)")
                        self.pastWeekDistanceDictionary.forEach({ (key, value) in
                            //If timestamp matches
                            let calendar = NSCalendar.current
                            if (calendar.compare(key, to: convertedTimestamp as Date, toGranularity: .day) == ComparisonResult.orderedSame) {
                                self.pastWeekDurationDictionary[key]! += run.time!
                                self.pastWeekDistanceDictionary[key]! += run.distance!
                                self.pastWeekCaloriesDictionary[key]! += Int(run.distance!*0.72*Double(self.bodyweight))
                                print("Run: \(run.distance!) * 0.72 * \(self.bodyweight)")
                                print("Value before Int: \(run.distance!*0.72*Double(self.bodyweight))")
                                print("Success")
                            }
                        })
                    }
                    
                    self.updateGraphs()
                }
            }
        }
    }
    
    func getDayOfWeek(date: Date) -> String? {
        let weekDay = Calendar.current.component(.weekday, from: date)
            switch weekDay {
            case 1:
                return "Sun"
            case 2:
                return "Mon"
            case 3:
                return "Tue"
            case 4:
                return "Wed"
            case 5:
                return "Thu"
            case 6:
                return "Fri"
            case 7:
                return "Sat"
            default:
                print("Error fetching days")
                return "Day"
            }
    }
    
    func updateGraphs() {
        if (currentIndex == 0) {
            let durationVC = self.orderedViewControllers[0] as! DurationViewController
            durationVC.value1Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[0]]!)
            durationVC.value2Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[1]]!)
            durationVC.value3Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[2]]!)
            durationVC.value4Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[3]]!)
            durationVC.value5Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[4]]!)
            durationVC.value6Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[5]]!)
            durationVC.value7Label.text = secondsToFormattedDuration(seconds: self.pastWeekDurationDictionary[self.pastWeekArray[6]]!)
            
            durationVC.day1Label.text = self.getDayOfWeek(date: self.pastWeekArray[0])
            durationVC.day2Label.text = self.getDayOfWeek(date: self.pastWeekArray[1])
            durationVC.day3Label.text = self.getDayOfWeek(date: self.pastWeekArray[2])
            durationVC.day4Label.text = self.getDayOfWeek(date: self.pastWeekArray[3])
            durationVC.day5Label.text = self.getDayOfWeek(date: self.pastWeekArray[4])
            durationVC.day6Label.text = self.getDayOfWeek(date: self.pastWeekArray[5])
            durationVC.day7Label.text = self.getDayOfWeek(date: self.pastWeekArray[6])
            
            /*
            var frameRect1 = durationVC.bar1Image.frame
            frameRect1.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[0]]!)
            durationVC.bar1Image.frame = frameRect1
            var frameRect2 = durationVC.bar2Image.frame
            frameRect2.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[1]]!)
            durationVC.bar2Image.frame = frameRect2
            var frameRect3 = durationVC.bar3Image.frame
            frameRect3.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[2]]!)
            durationVC.bar3Image.frame = frameRect3
            var frameRect4 = durationVC.bar4Image.frame
            frameRect4.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[3]]!)
            durationVC.bar4Image.frame = frameRect4
            var frameRect5 = durationVC.bar5Image.frame
            frameRect5.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[4]]!)
            durationVC.bar5Image.frame = frameRect5
            var frameRect6 = durationVC.bar6Image.frame
            frameRect6.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[5]]!)
            durationVC.bar6Image.frame = frameRect6
            var frameRect7 = durationVC.bar7Image.frame
            frameRect7.size.height = CGFloat(self.pastWeekDurationDictionary[self.pastWeekArray[6]]!)
            durationVC.bar7Image.frame = frameRect7
             */
            
            durationVC.bar1Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[0]]! + 1))).isActive = true
            durationVC.bar2Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[1]]! + 1))).isActive = true
            durationVC.bar3Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[2]]! + 1))).isActive = true
            durationVC.bar4Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[3]]! + 1))).isActive = true
            durationVC.bar5Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[4]]! + 1))).isActive = true
            durationVC.bar6Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[5]]! + 1))).isActive = true
            durationVC.bar7Image.heightAnchor.constraint(equalToConstant: CGFloat((80.0/3600.0) * Double(self.pastWeekDurationDictionary[self.pastWeekArray[6]]! + 1))).isActive = true
            
            if (durationVC.value1Label.text != "0:00") {
                durationVC.bar1Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (durationVC.value2Label.text != "0:00") {
                durationVC.bar2Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (durationVC.value3Label.text != "0:00") {
                durationVC.bar3Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (durationVC.value4Label.text != "0:00") {
                durationVC.bar4Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (durationVC.value5Label.text != "0:00") {
                durationVC.bar5Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (durationVC.value6Label.text != "0:00") {
                durationVC.bar6Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (durationVC.value7Label.text != "0:00") {
                durationVC.bar7Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            
            durationVC.dimOverlay.isHidden = true
            
            durationVC.loadingSpinner.stopAnimating()
            
            durationVC.loadingSpinner.isHidden = true
        }
        else if (currentIndex == 1) {
            let distanceVC = self.orderedViewControllers[1] as! DistanceViewController
            distanceVC.value1Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[0]]!))
            distanceVC.value2Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[1]]!))
            distanceVC.value3Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[2]]!))
            distanceVC.value4Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[3]]!))
            distanceVC.value5Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[4]]!))
            distanceVC.value6Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[5]]!))
            distanceVC.value7Label.text = String(format: "%.2f", self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[6]]!))
            
            distanceVC.day1Label.text = self.getDayOfWeek(date: self.pastWeekArray[0])
            distanceVC.day2Label.text = self.getDayOfWeek(date: self.pastWeekArray[1])
            distanceVC.day3Label.text = self.getDayOfWeek(date: self.pastWeekArray[2])
            distanceVC.day4Label.text = self.getDayOfWeek(date: self.pastWeekArray[3])
            distanceVC.day5Label.text = self.getDayOfWeek(date: self.pastWeekArray[4])
            distanceVC.day6Label.text = self.getDayOfWeek(date: self.pastWeekArray[5])
            distanceVC.day7Label.text = self.getDayOfWeek(date: self.pastWeekArray[6])
            
            distanceVC.bar1Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[0]]!) + 1)).isActive = true
            distanceVC.bar2Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[1]]!) + 1)).isActive = true
            distanceVC.bar3Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[2]]!) + 1)).isActive = true
            distanceVC.bar4Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[3]]!) + 1)).isActive = true
            distanceVC.bar5Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[4]]!) + 1)).isActive = true
            distanceVC.bar6Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[5]]!) + 1)).isActive = true
            distanceVC.bar7Image.heightAnchor.constraint(equalToConstant: CGFloat(8 * self.roundToTwoDecimals(double: self.pastWeekDistanceDictionary[self.pastWeekArray[6]]!) + 1)).isActive = true
            
            if (distanceVC.value1Label.text != "0.00") {
                distanceVC.bar1Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (distanceVC.value2Label.text != "0.00") {
                distanceVC.bar2Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (distanceVC.value3Label.text != "0.00") {
                distanceVC.bar3Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (distanceVC.value4Label.text != "0.00") {
                distanceVC.bar4Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (distanceVC.value5Label.text != "0.00") {
                distanceVC.bar5Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (distanceVC.value6Label.text != "0.00") {
                distanceVC.bar6Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (distanceVC.value7Label.text != "0.00") {
                distanceVC.bar7Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            
            distanceVC.dimOverlay.isHidden = true
            
            distanceVC.loadingSpinner.stopAnimating()
            
            distanceVC.loadingSpinner.isHidden = true
        }
        else if (currentIndex == 2) {
            let caloriesVC = self.orderedViewControllers[2] as! CaloriesViewController
            caloriesVC.value1Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[0]]!)"
            caloriesVC.value2Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[1]]!)"
            caloriesVC.value3Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[2]]!)"
            caloriesVC.value4Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[3]]!)"
            caloriesVC.value5Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[4]]!)"
            caloriesVC.value6Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[5]]!)"
            caloriesVC.value7Label.text = "\(self.pastWeekCaloriesDictionary[self.pastWeekArray[6]]!)"
            
            caloriesVC.day1Label.text = self.getDayOfWeek(date: self.pastWeekArray[0])
            caloriesVC.day2Label.text = self.getDayOfWeek(date: self.pastWeekArray[1])
            caloriesVC.day3Label.text = self.getDayOfWeek(date: self.pastWeekArray[2])
            caloriesVC.day4Label.text = self.getDayOfWeek(date: self.pastWeekArray[3])
            caloriesVC.day5Label.text = self.getDayOfWeek(date: self.pastWeekArray[4])
            caloriesVC.day6Label.text = self.getDayOfWeek(date: self.pastWeekArray[5])
            caloriesVC.day7Label.text = self.getDayOfWeek(date: self.pastWeekArray[6])
            
            caloriesVC.bar1Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[0]]! + 10))).isActive = true
            caloriesVC.bar2Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[1]]! + 10))).isActive = true
            caloriesVC.bar3Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[2]]! + 10))).isActive = true
            caloriesVC.bar4Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[3]]! + 10))).isActive = true
            caloriesVC.bar5Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[4]]! + 10))).isActive = true
            caloriesVC.bar6Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[5]]! + 10))).isActive = true
            caloriesVC.bar7Image.heightAnchor.constraint(equalToConstant: CGFloat(0.1 * Double(self.pastWeekCaloriesDictionary[self.pastWeekArray[6]]! + 10))).isActive = true
            
            if (caloriesVC.value1Label.text != "0") {
                caloriesVC.bar1Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (caloriesVC.value2Label.text != "0") {
                caloriesVC.bar2Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (caloriesVC.value3Label.text != "0") {
                caloriesVC.bar3Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (caloriesVC.value4Label.text != "0") {
                caloriesVC.bar4Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (caloriesVC.value5Label.text != "0") {
                caloriesVC.bar5Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (caloriesVC.value6Label.text != "0") {
                caloriesVC.bar6Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            if (caloriesVC.value7Label.text != "0") {
                caloriesVC.bar7Image.backgroundColor = UIColor.init(red: 98/255.0, green: 239/255.0, blue: 99/255.0, alpha: 1.0)
            }
            
            caloriesVC.dimOverlay.isHidden = true
            
            caloriesVC.loadingSpinner.stopAnimating()
            
            caloriesVC.loadingSpinner.isHidden = true
        }
    }
    
    func secondsToFormattedDuration(seconds: Int) -> String {
        let minutes = seconds/60
        let seconds = seconds%60
        let minutesString = "\(minutes)"
        var secondsString = ""
        if (seconds < 10) {
            secondsString = "0\(seconds)"
        }
        else {
            secondsString = "\(seconds)"
        }
        return "\(minutesString):\(secondsString)"
    }
    
    func getDateFromTimestamp(timestamp: TimeInterval) -> String {
        let myTimeInterval = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: TimeInterval(myTimeInterval))
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
        return "\(calendarDate.month)/\(calendarDate.day!)"
        return monthIntToString(monthInt: calendarDate.month!)
    }
    
    func getMonthFromTimestamp(timestamp: TimeInterval) -> String {
        let myTimeInterval = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: TimeInterval(myTimeInterval))
        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
        return monthIntToString(monthInt: calendarDate.month!)
    }
    
    func monthIntToString(monthInt: Int) -> String {
        switch (monthInt) {
        case 1:
            return "January"
        case 2:
            return "February"
        case 3:
            return "March"
        case 4:
            return "April"
        case 5:
            return "May"
        case 6:
            return "June"
        case 7:
            return "July"
        case 8:
            return "August"
        case 9:
            return "September"
        case 10:
            return "October"
        case 11:
            return "November"
        case 12:
            return "December"
        default:
            return ""
        }
    }
    
    func roundToTwoDecimals(double: Double) -> Double {
        return (double*100).rounded()/100
    }
    
    func getPastWeek() {
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        var days = [Date]()
        for i in 1 ... 7 {
            days.insert(date, at: 0)
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        print("Days: \(days)")
        pastWeekArray = days
        pastWeekDurationDictionary = days.reduce(into: [:], { result, next in
            result[next] = 0 })
        pastWeekDistanceDictionary = days.reduce(into: [:], { result, next in
            result[next] = 0.0 })
        pastWeekCaloriesDictionary = days.reduce(into: [:], { result, next in
            result[next] = 0 })
    }
}





