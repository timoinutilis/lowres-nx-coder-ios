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
    
    var isCloudEnabled: Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }
    
    private(set) var items: [ExplorerItem]?
    
    private(set) lazy var localDocumentsUrl: URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    
    private(set) var ubiquitousContainerUrl: URL?
    
    var ubiquitousDocumentsUrl: URL? {
        return ubiquitousContainerUrl?.appendingPathComponent("Documents")
    }
    
    var currentDocumentsUrl: URL {
        if isCloudEnabled {
            return ubiquitousDocumentsUrl!
        } else {
            return localDocumentsUrl
        }
    }
    
    func setup(completion: @escaping (() -> Void)) {
        if FileManager.default.ubiquityIdentityToken != nil {
            DispatchQueue.global().async {
                self.ubiquitousContainerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    func addNewProject(completion: @escaping ((ExplorerItem?, Error?) -> Void)) {
        let date = Date()
        let name = "New Program \(Int(date.timeIntervalSinceReferenceDate)).nx"
        let url = localDocumentsUrl.appendingPathComponent(name)
        
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var resultItem: ExplorerItem?
            var resultError: Error?
            fileCoordinator.coordinate(writingItemAt: url, options: .forReplacing, error: nil) { (url) in
                if FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) {
                    let item = ExplorerItem(fileUrl: url)
                    if self.isCloudEnabled {
                        do {
                            try self.moveItemToCloud(item)
                            resultItem = item
                        } catch {
                            resultError = error
                        }
                    } else {
                        resultItem = item
                    }
                }
            }
            DispatchQueue.main.async {
                completion(resultItem, resultError)
            }
        }
    }
    
    func copyBundleProgramsIfNeeded() throws {
        /*
         let programsUrl = Bundle.main.bundleURL.appendingPathComponent("programs", isDirectory: true)
         let urls = try FileManager.default.contentsOfDirectory(at: programsUrl, includingPropertiesForKeys: nil, options: [])
         for url in urls {
         let targetUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
         if !FileManager.default.fileExists(atPath: targetUrl.path) {
         try FileManager.default.copyItem(at: url, to: targetUrl)
         }
         }
         */
    }
    
    private func moveItemToCloud(_ item: ExplorerItem) throws {
        guard let documentsUrl = ubiquitousDocumentsUrl else {
            return
        }
        let sourceUrl = item.fileUrl
        let fileName = sourceUrl.lastPathComponent
        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
        try FileManager.default.setUbiquitous(true, itemAt: sourceUrl, destinationURL: destinationUrl)
        item.fileUrl = destinationUrl
    }
    
}
