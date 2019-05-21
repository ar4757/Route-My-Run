//
//  TabVBarController.swift
//  Running App
//
//  Created by Andrew Ratz on 1/16/19.
//  Copyright © 2019 Andrew Ratz. All rights reserved.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {
    
    @IBInspectable var defaultIndex: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        selectedIndex = defaultIndex

    }
    
}
