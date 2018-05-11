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
            
            if self.isCloudEnabled {
                self.ubiquitousContainerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)
                do {
                    try self.copyLocalProjectsToCloud()
                } catch {
                    print("copyLocalProjectsToCloud:", error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.setupCloudIcons()
                completion()
            }
        }
    }
    
    //MARK: - Programs
    
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
                    self.postNotification(name: .ProjectManagerDidAddProgram, for: item)
                }
            }
        }
    }
    
    func addProject(originalName: String, programData: Data?, completion: @escaping ((Error?) -> Void)) {
        let name = availableProgramName(original: originalName)
        let programUrl = localDocumentsUrl.appendingPathComponent(name).appendingPathExtension("nx")
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var resultItem: ExplorerItem?
            var resultError: Error?
            var coordError: NSError?
            fileCoordinator.coordinate(writingItemAt: programUrl, options: .forReplacing, error: &coordError) { (url) in
                if FileManager.default.createFile(atPath: url.path, contents: programData, attributes: nil) {
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
                    self.postNotification(name: .ProjectManagerDidAddProgram, for: item)
                }
            }
        }
    }
    
    private func availableProgramName(original: String) -> String {
        var name = original
        var ok = false
        var count = 1
        repeat {
            ok = true
            let localUrl = localDocumentsUrl.appendingPathComponent(name).appendingPathExtension("nx")
            var existsInCloud = false
            if let ubiquitousDocumentsUrl = ubiquitousDocumentsUrl {
                let cloudUrl = ubiquitousDocumentsUrl.appendingPathComponent(name).appendingPathExtension("nx")
                if FileManager.default.fileExists(atPath: cloudUrl.path) {
                    existsInCloud = true
                } else {
                    existsInCloud = FileManager.default.isUbiquitousItem(at: cloudUrl)
                }
            }
            if FileManager.default.fileExists(atPath: localUrl.path) || existsInCloud {
                ok = false
                count += 1
                name = "\(original) (\(count))"
            }
        } while !ok
        return name
    }
    
    func deleteProject(item: ExplorerItem, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var success = false
            var resultError: Error?
            var coordError: NSError?
            
            // program file
            print("deleteProject", item.fileUrl)
            fileCoordinator.coordinate(writingItemAt: item.fileUrl, options: .forDeleting, error: &coordError, byAccessor: { (url) in
                do {
                    try FileManager.default.removeItem(at: url)
                    success = true
                } catch {
                    resultError = error
                }
            })
            
            // image file
            if success {
                let imageUrl = item.imageUrl
                if FileManager.default.fileExists(atPath: imageUrl.path) {
                    fileCoordinator.coordinate(writingItemAt: imageUrl, options: .forDeleting, error: nil, byAccessor: { (url) in
                        do {
                            try FileManager.default.removeItem(at: url)
                        } catch {
                            print("delete image:", error)
                        }
                    })
                }
            }
            
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
        let srcImageUrl = item.imageUrl
        
        DispatchQueue.global().async {
            let fileCoordinator = NSFileCoordinator()
            var success = false
            var resultError: Error?
            var coordError: NSError?
            
            // program file
            print("renameProject", item.fileUrl)
            fileCoordinator.coordinate(writingItemAt: item.fileUrl, options: .forMoving, writingItemAt: destUrl, options: .forReplacing, error: &coordError, byAccessor: { (sourceUrl, destUrl) in
                do {
                    try FileManager.default.moveItem(at: sourceUrl, to: destUrl)
                    item.fileUrl = destUrl
                    success = true
                } catch {
                    resultError = error
                }
            })
            
            // image file
            if success {
                if FileManager.default.fileExists(atPath: srcImageUrl.path) {
                    let destImageUrl = item.imageUrl
                    fileCoordinator.coordinate(writingItemAt: srcImageUrl, options: .forMoving, writingItemAt: destImageUrl, options: .forReplacing, error: nil, byAccessor: { (sourceUrl, destUrl) in
                        do {
                            try FileManager.default.moveItem(at: sourceUrl, to: destUrl)
                        } catch {
                            print("rename image:", error)
                        }
                    })
                }
            }
            
            if !success && coordError != nil {
                resultError = coordError
            }
            DispatchQueue.main.async {
                completion(resultError)
            }
        }
    }
    
    func saveProjectIcon(programUrl: URL, image: UIImage) {
        let iconUrl = programUrl.deletingPathExtension().appendingPathExtension("png")
        DispatchQueue.global().async {
            if let pngData = UIImagePNGRepresentation(image) {
                let fileCoordinator = NSFileCoordinator()
                var coordError: NSError?
                fileCoordinator.coordinate(writingItemAt: iconUrl, options: .forReplacing, error: &coordError) { (url) in
                    do {
                        try pngData.write(to: url)
                    } catch {
                        print("saveProjectIcon:", error.localizedDescription)
                    }
                }
                if let error = coordError {
                    print("saveProjectIcon:", error.localizedDescription)
                }
            } else {
                print("saveProjectIcon: failed to create PNG data")
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
                        self.postNotification(name: .ProjectManagerDidAddProgram, for: ExplorerItem(fileUrl: document.fileURL))
                        completion(document, nil)
                    } else {
                        completion(nil, NSError(domain: "LowResNXCoder", code: 0, userInfo: [NSLocalizedDescriptionKey: "“Disk.nx” could not be created."]))
                    }
                })
            }
        }
    }
    
    private func postNotification(name: NSNotification.Name, for item: ExplorerItem) {
        NotificationCenter.default.post(name: name, object: self, userInfo: ["item": item])
    }
    
    //MARK: - Bundle Programs
    
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
    
    //MARK: - Cloud
    
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
    
    //MARK: - Cloud Icons
    
    private var iconsMetadataQuery: NSMetadataQuery?
    private var iconsQueryDidFinishGatheringObserver: Any?
    private var iconsQueryDidUpdateObserver: Any?
    
    private func setupCloudIcons() {
        let query = NSMetadataQuery()
        iconsMetadataQuery = query
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K LIKE '*.png'", NSMetadataItemFSNameKey)
        
        iconsQueryDidFinishGatheringObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSMetadataQueryDidFinishGathering,
            object: query,
            queue: nil,
            using: { [weak self] (notification) in
                self?.cloudIconListReceived(query: notification.object as! NSMetadataQuery)
            }
        )
        
        iconsQueryDidUpdateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSMetadataQueryDidUpdate,
            object: query,
            queue: nil,
            using: { [weak self] (notification) in
                self?.cloudIconListReceived(query: notification.object as! NSMetadataQuery)
            }
        )
        
        query.start()
    }
    
    private func removeCloudObservers() {
        iconsMetadataQuery?.stop()
        if iconsQueryDidFinishGatheringObserver != nil {
            NotificationCenter.default.removeObserver(iconsQueryDidFinishGatheringObserver!)
            iconsQueryDidFinishGatheringObserver = nil
        }
        if iconsQueryDidUpdateObserver != nil {
            NotificationCenter.default.removeObserver(iconsQueryDidUpdateObserver!)
            iconsQueryDidUpdateObserver = nil
        }
    }
    
    private func cloudIconListReceived(query: NSMetadataQuery) {
        query.disableUpdates()
        for result in query.results as! [NSMetadataItem] {
            let status = result.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as! String
            let isDownloading = result.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as! Bool
            if status == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded && !isDownloading {
                let url = result.value(forAttribute: NSMetadataItemURLKey) as! URL
                do {
                    print("startDownloadingUbiquitousItem:", url)
                    try FileManager.default.startDownloadingUbiquitousItem(at: url)
                } catch {
                    print("startDownloadingUbiquitousItem:", error.localizedDescription)
                }
            }
        }
        query.enableUpdates()
    }
    
}
