//
//  ExplorerItem.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 28/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class ExplorerItem: NSObject {
    
    var fileUrl: URL
    var isDefault = false
    
    var name: String {
        return fileUrl.deletingPathExtension().lastPathComponent
    }
    
    var image: UIImage {
        do {
            let iconUrl = fileUrl.deletingPathExtension().appendingPathExtension("png")
            let iconData = try Data(contentsOf: iconUrl)
            if let image = UIImage(data: iconData) {
                return image
            }
        } catch {
        }
        return UIImage(named:"icon_project")!
    }
    
    init(fileUrl: URL) {
        self.fileUrl = fileUrl
        super.init()
    }
    
}
