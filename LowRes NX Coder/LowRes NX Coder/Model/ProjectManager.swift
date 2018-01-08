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
        print("localDocumentsUrl:", localDocumentsUrl)
        DispatchQueue.global().async {
            do {
                try self.copyBundleProgramsIfNeeded()
            } catch {
                print("copyBundleProgramsIfNeeded:", error.localizedDescription)
            }
            
            if FileManager.default.ubiquityIdentityToken != nil {
                self.ubiquitousContainerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                do {
                    try self.copyLocalProjectsToCloud()
                } catch {
                    print("copyLocalProjectsToCloud:", error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                completion()
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
            var coordError: NSError?
            fileCoordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordError) { (url) in
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
            if resultItem == nil && coordError != nil {
                resultError = coordError
            }
            DispatchQueue.main.async {
                completion(resultError)
                if let item = resultItem {
                    self.postNotification(for: item)
                }
            }
        }
    }
    
    func deleteProject(item: ExplorerItem, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var success = false
            var resultError: Error?
            var coordError: NSError?
            fileCoordinator.coordinate(writingItemAt: item.fileUrl, options: .forDeleting, error: &coordError, byAccessor: { (url) in
                do {
                    try FileManager.default.removeItem(at: url)
                    success = true
                } catch {
                    resultError = error
                }
            })
            if !success && coordError != nil {
                resultError = coordError
            }
            DispatchQueue.main.async {
                completion(resultError)
            }
        }
    }
    
    func renameProject(item: ExplorerItem, newName: String, completion: @escaping (Error?) -> Void) {
        let destUrl = item.fileUrl.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension("nx")
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var success = false
            var resultError: Error?
            var coordError: NSError?
            fileCoordinator.coordinate(writingItemAt: item.fileUrl, options: .forMoving, writingItemAt: destUrl, options: .forReplacing, error: &coordError, byAccessor: { (sourceUrl, destUrl) in
                do {
                    try FileManager.default.moveItem(at: sourceUrl, to: destUrl)
                    item.fileUrl = destUrl
                    success = true
                } catch {
                    resultError = error
                }
            })
            if !success && coordError != nil {
                resultError = coordError
            }
            DispatchQueue.main.async {
                completion(resultError)
            }
        }
    }
    
    func getDiskDocument(completion: @escaping (ProjectDocument?, Error?) -> Void) {
        let fileUrl = currentDocumentsUrl.appendingPathComponent("Disk.nx")
        let document = ProjectDocument(fileURL: fileUrl)
        document.open { (success) in
            if success {
                if document.documentState == .normal {
                    completion(document, nil)
                } else {
                    completion(nil, NSError(domain: "LowResNXCoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "“Disk.nx” is currently not editable."]))
                }
            } else {
                document.save(to: document.fileURL, for: .forCreating, completionHandler: { (success) in
                    if success {
                        self.postNotification(for: ExplorerItem(fileUrl: document.fileURL))
                        completion(document, nil)
                    } else {
                        completion(nil, NSError(domain: "LowResNXCoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "“Disk.nx” could not be created."]))
                    }
                })
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
    
    private var copiedBundleProgramsKey: String {
        var key = "CopiedBundlePrograms"
        if let token = FileManager.default.ubiquityIdentityToken  {
            key += token.description
        }
        return key
    }
    
    private func shouldCopyBundleProgram(filename: String) -> Bool {
        let copiedPrograms: [String] = UserDefaults.standard.array(forKey: copiedBundleProgramsKey) as? [String] ?? []
        return !copiedPrograms.contains(filename)
    }
    
    private func didCopyBundleProgram(filename: String) {
        var copiedPrograms: [String] = UserDefaults.standard.array(forKey: copiedBundleProgramsKey) as? [String] ?? []
        copiedPrograms.append(filename)
        UserDefaults.standard.set(copiedPrograms, forKey: copiedBundleProgramsKey)
    }
    
    private func copyLocalProjectsToCloud() throws {
        let urls = try FileManager.default.contentsOfDirectory(at: self.localDocumentsUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for url in urls {
            if !url.hasDirectoryPath {
                let item = ExplorerItem(fileUrl: url)
                try self.moveItemToCloud(item)
            }
        }
    }
    
    private func moveItemToCloud(_ item: ExplorerItem) throws {
        guard let documentsUrl = ubiquitousDocumentsUrl else {
            return
        }
        let sourceUrl = item.fileUrl
        let fileName = sourceUrl.lastPathComponent
        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
        if !FileManager.default.isUbiquitousItem(at: destinationUrl) {
            try FileManager.default.setUbiquitous(true, itemAt: sourceUrl, destinationURL: destinationUrl)
        }
        item.fileUrl = destinationUrl
    }
    
}
