//
//  Project.swift
//  LowRes Coder NX
//
//  Created by Timo Kloss on 24/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class Project: NSObject {
    
    var fileUrl: URL?
    var isDefault = false
    
    var name: String {
        if let fileUrl = fileUrl {
            return fileUrl.deletingPathExtension().lastPathComponent
        }
        return "Unnamed Program"
    }
    
    var image: UIImage {
        if let fileUrl = self.fileUrl {
            do {
                let iconUrl = fileUrl.deletingPathExtension().appendingPathExtension("png")
                let iconData = try Data(contentsOf: iconUrl)
                if let image = UIImage(data: iconData) {
                    return image
                }
            } catch {
            }
        }
        return UIImage(named:"icon_project")!
    }
    
    private var _sourceCode: String?
    
    var sourceCode: String? {
        set {
            _sourceCode = newValue
        }
        get {
            if _sourceCode == nil {
                if let fileUrl = fileUrl {
                    _sourceCode = try? String(contentsOf: fileUrl)
                }
            }
            return _sourceCode
        }
    }
    
    
    init(fileUrl: URL?) {
        self.fileUrl = fileUrl
        super.init()
    }
    
}
