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
        return #imageLiteral(resourceName: "sharecommunity")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        let programUrl = activityItems.first as! URL
        
        let vc = ShareViewController(style: .grouped)
        vc.setup(activity: self, programUrl: programUrl)
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        
        shareViewController = nav
    }
    
    override var activityViewController: UIViewController? {
        return shareViewController
    }
    
}
