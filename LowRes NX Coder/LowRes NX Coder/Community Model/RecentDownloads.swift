//
//  RecentDownloads.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 12/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class RecentDownloads: NSObject {

    let userDefaultsKey = "UserDefaultsRecentDownloads"
    let maxTime: TimeInterval = 30 * 24 * 60 * 60
    
    @objc func contains(_ post: LCCPost) -> Bool {
        if let recentDownloads = UserDefaults.standard.object(forKey: userDefaultsKey) as? [String : Date] {
            if let date = recentDownloads[post.objectId], date.timeIntervalSinceNow >= -maxTime {
                return true
            }
        }
        return false
    }
    
    @objc func add(_ post: LCCPost) {
        var recentDownloads = (UserDefaults.standard.object(forKey: userDefaultsKey) as? [String : Date]) ?? [String : Date]()
        recentDownloads[post.objectId] = Date()
        UserDefaults.standard.set(recentDownloads, forKey: userDefaultsKey)
    }
    
    @objc func clean() {
        guard let recentDownloads = UserDefaults.standard.object(forKey: userDefaultsKey) as? [String : Date] else {
            return
        }
        var updatedEntries = recentDownloads
        for (postId, date) in recentDownloads {
            if date.timeIntervalSinceNow < -maxTime {
                updatedEntries.removeValue(forKey: postId)
            }
        }
        if updatedEntries.count != recentDownloads.count {
            UserDefaults.standard.set(updatedEntries, forKey: userDefaultsKey)
        }
    }
    
}
