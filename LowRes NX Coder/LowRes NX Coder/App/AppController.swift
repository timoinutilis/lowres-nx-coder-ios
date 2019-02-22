//
//  AppController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 22/02/2019.
//  Copyright © 2019 Inutilis Software. All rights reserved.
//

import UIKit

@objc class AppController: NSObject {
    
    private static let hasDontatedKey = "hasDontated"
    private static let isSafeScaleEnabledKey = "isSafeScaleEnabled"

    @objc static let shared = AppController()
    
    @objc weak var tabBarController: TabBarController!
    
    @objc let helpContent: HelpContent
    @objc let bootTime: CFAbsoluteTime
    
    var hasDontated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppController.hasDontatedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppController.hasDontatedKey)
        }
    }
    
    var isSafeScaleEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: AppController.isSafeScaleEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppController.isSafeScaleEnabledKey)
        }
    }
    
    private override init() {
        let url = Bundle.main.url(forResource: "manual", withExtension: "html", subdirectory:"docs")!
        helpContent = HelpContent(url: url)
        
        bootTime = CFAbsoluteTimeGetCurrent()
    }
    
}
