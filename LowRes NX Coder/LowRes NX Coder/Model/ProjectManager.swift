//
//  ProjectManager.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 24/11/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let ProjectManagerDidAddProgram = Notification.Name("ProjectManagerDidAddProgram")
}

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
        DispatchQueue.global().async {
            do {
                try self.copyBundleProgramsIfNeeded()
            } catch {
                print("copyBundleProgramsIfNeeded:", error.localizedDescription)
            }
            
            if FileManager.default.ubiquityIdentityToken != nil {
                self.ubiquitousContainerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func copyLocalProjectsToCloud(completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async {
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: self.localDocumentsUrl, includingPropertiesForKeys: nil, options: [])
                for url in urls {
                    let item = ExplorerItem(fileUrl: url)
                    try self.moveItemToCloud(item)
                }
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    func importProgram(from url: URL, completion: @escaping ((Error?) -> Void)) {
        let destUrl = ProjectManager.shared.localDocumentsUrl.appendingPathComponent(url.lastPathComponent)
        
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var resultItem: ExplorerItem?
            var resultError: Error?
            fileCoordinator.coordinate(writingItemAt: url, options: .forReplacing, error: nil) { (url) in
                do {
                    try FileManager.default.moveItem(at: url, to: destUrl)
                    let item = ExplorerItem(fileUrl: destUrl)
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
                } catch {
                    resultError = error
                }
            }
            DispatchQueue.main.async {
                completion(resultError)
                if let item = resultItem {
                    self.postNotification(for: item)
                }
            }
        }
    }
    
    func addNewProject(completion: @escaping ((Error?) -> Void)) {
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
                completion(resultError)
                if let item = resultItem {
                    self.postNotification(for: item)
                }
            }
        }
    }
    
    private func postNotification(for item: ExplorerItem) {
        NotificationCenter.default.post(name: NSNotification.Name.ProjectManagerDidAddProgram, object: self, userInfo: ["item": item])
    }
    
    private func copyBundleProgramsIfNeeded() throws {
        let programsUrl = Bundle.main.bundleURL.appendingPathComponent("programs", isDirectory: true)
        let urls = try FileManager.default.contentsOfDirectory(at: programsUrl, includingPropertiesForKeys: nil, options: [])
        for url in urls {
            let filename = url.lastPathComponent
            if shouldCopyBundleProgram(filename: filename) {
                let targetUrl = localDocumentsUrl.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: targetUrl.path) {
                    didCopyBundleProgram(filename: filename)
                } else {
                    let fileCoordinator = NSFileCoordinator()
                    var copyError: Error?
                    fileCoordinator.coordinate(writingItemAt: targetUrl, options: .forReplacing, error: nil) { (targetUrl) in
                        do {
                            try FileManager.default.copyItem(at: url, to: targetUrl)
                            didCopyBundleProgram(filename: filename)
                        } catch {
                            copyError = error
                        }
                    }
                    if let copyError = copyError {
                        throw copyError
                    }
                }
            }
        }
    }
    
    private func shouldCopyBundleProgram(filename: String) -> Bool {
        let copiedPrograms: [String] = UserDefaults.standard.array(forKey: "CopiedBundlePrograms") as? [String] ?? []
        return !copiedPrograms.contains(filename)
    }
    
    private func didCopyBundleProgram(filename: String) {
        var copiedPrograms: [String] = UserDefaults.standard.array(forKey: "CopiedBundlePrograms") as? [String] ?? []
        copiedPrograms.append(filename)
        UserDefaults.standard.set(copiedPrograms, forKey: "CopiedBundlePrograms")
    }
    
    private func moveItemToCloud(_ item: ExplorerItem) throws {
        guard let documentsUrl = ubiquitousDocumentsUrl else {
            return
        }
        let sourceUrl = item.fileUrl
        let fileName = sourceUrl.lastPathComponent
        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
        if FileManager.default.isUbiquitousItem(at: destinationUrl) {
            // already in iCloud, delete source item
            try FileManager.default.removeItem(at: sourceUrl)
        } else {
            // move to iCloud
            try FileManager.default.setUbiquitous(true, itemAt: sourceUrl, destinationURL: destinationUrl)
        }
        item.fileUrl = destinationUrl
    }
    
}
