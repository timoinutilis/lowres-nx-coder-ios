//
//  ProjectManager.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 24/11/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class ProjectManager: NSObject {

    class var shared: ProjectManager {
        struct Static {
            static let instance: ProjectManager = ProjectManager()
        }
        return Static.instance
    }
    
    func copyBundleProgramsIfNeeded() throws {
        let programsUrl = Bundle.main.bundleURL.appendingPathComponent("programs", isDirectory: true)
        let urls = try FileManager.default.contentsOfDirectory(at: programsUrl, includingPropertiesForKeys: nil, options: [])
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        for url in urls {
            let targetUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
            if !FileManager.default.fileExists(atPath: targetUrl.path) {
                try FileManager.default.copyItem(at: url, to: targetUrl)
            }
        }
    }
    
}
