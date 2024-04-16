//
//  TabController.swift
//  Bytes2
//

import UIKit

class TabController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.unselectedItemTintColor = UIColor(named: "bytesBeige")
        
        if let items = tabBar.items {

            // Setting selected vs. unselected icon image
            let unselectedIcon = UIImage(named: "micButton")
            let selectedIcon = UIImage(named: "micButtonSelected")

            items[2].image = unselectedIcon?.withRenderingMode(.alwaysOriginal)
            items[2].selectedImage = selectedIcon?.withRenderingMode(.alwaysOriginal)


            // Shift the items
            let horizontalOffset: CGFloat = 19.0
            let verticalOffset: CGFloat = 8.0
            items[0].imageInsets = UIEdgeInsets(top: verticalOffset, left: 0, bottom: -verticalOffset, right: 0)
            items[1].imageInsets = UIEdgeInsets(top: verticalOffset, left: -horizontalOffset, bottom: -verticalOffset, right: horizontalOffset)
            items[2].imageInsets = UIEdgeInsets(top: verticalOffset, left: 0, bottom: -verticalOffset, right: 0)
            items[3].imageInsets = UIEdgeInsets(top: verticalOffset, left: horizontalOffset, bottom: -verticalOffset, right: -horizontalOffset)
            items[4].imageInsets = UIEdgeInsets(top: verticalOffset, left: 0, bottom: -verticalOffset, right: 0)
                        
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}
