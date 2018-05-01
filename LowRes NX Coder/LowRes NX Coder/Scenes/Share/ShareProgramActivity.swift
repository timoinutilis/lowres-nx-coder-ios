//
//  ShareProgramActivity.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 1/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class ShareProgramActivity: UIActivity {
    
    static let shareWithCommunity = UIActivityType("shareWithCommunity")
    
    private var shareViewController: UIViewController?
    
    override class var activityCategory: UIActivityCategory {
        return .action
    }
    
    override var activityType: UIActivityType? {
        return ShareProgramActivity.shareWithCommunity
    }
    
    override var activityTitle: String? {
        return "Share With Community"
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "icon_about")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        let programUrl = activityItems.first as! URL
        
        let storyboard = UIStoryboard(name: "Share", bundle: nil)
        let nav = storyboard.instantiateInitialViewController() as! UINavigationController
        let vc = nav.topViewController as! ShareViewController
        vc.setup(activity: self, programUrl: programUrl)
        shareViewController = nav
    }
    
    override var activityViewController: UIViewController? {
        return shareViewController
    }
    
}
