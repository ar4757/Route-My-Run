
import UIKit
import Firebase
import FacebookCore
import FacebookLogin

class DurationViewController: UIViewController {
    var pageNumber: Int!

    @IBOutlet weak var day1Label: UILabel!
    @IBOutlet weak var day2Label: UILabel!
    @IBOutlet weak var day3Label: UILabel!
    @IBOutlet weak var day4Label: UILabel!
    @IBOutlet weak var day5Label: UILabel!
    @IBOutlet weak var day6Label: UILabel!
    @IBOutlet weak var day7Label: UILabel!
    @IBOutlet weak var value1Label: UILabel!
    @IBOutlet weak var value2Label: UILabel!
    @IBOutlet weak var value3Label: UILabel!
    @IBOutlet weak var value4Label: UILabel!
    @IBOutlet weak var value5Label: UILabel!
    @IBOutlet weak var value6Label: UILabel!
    @IBOutlet weak var value7Label: UILabel!
    @IBOutlet weak var bar1Image: UIImageView!
    @IBOutlet weak var bar2Image: UIImageView!
    @IBOutlet weak var bar3Image: UIImageView!
    @IBOutlet weak var bar4Image: UIImageView!
    @IBOutlet weak var bar5Image: UIImageView!
    @IBOutlet weak var bar6Image: UIImageView!
    @IBOutlet weak var bar7Image: UIImageView!
    @IBOutlet weak var dimOverlay: UIView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        dimOverlay.isHidden = false
        
        loadingSpinner.startAnimating()
    }
}
