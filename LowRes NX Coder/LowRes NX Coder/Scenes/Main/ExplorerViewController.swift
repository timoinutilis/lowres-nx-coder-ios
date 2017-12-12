//
//  ExplorerViewController.swift
//  LowRes Coder NX
//
//  Created by Timo Kloss on 24/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class ExplorerViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, ExplorerItemCellDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var items: [ExplorerItem]?
    var addedItem: ExplorerItem?
    
    private var metadataQuery: NSMetadataQuery?
    private var didAddProgramObserver: Any?
    private var queryDidFinishGatheringObserver: Any?
    private var queryDidUpdateObserver: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addProjectItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddProjectTapped))
//        let actionItem = UIBarButtonItem(image: UIImage(named:"folder"), style: .plain, target: self, action: #selector(onActionTapped))
        
//        navigationItem.rightBarButtonItems = [addProjectItem, actionItem]
        navigationItem.rightBarButtonItem = addProjectItem
        
        collectionView.dataSource = self
        collectionView.delegate = self
//        collectionView.draggable = true
        
        let layout = collectionView.collectionViewLayout as! DraggableCollectionViewFlowLayout
        layout.itemSize = CGSize(width: 110, height: 100)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        
        if ProjectManager.shared.isCloudEnabled {
            setupCloud()
        } else {
            loadLocalItems()
        }
    }
    
    deinit {
        removeCloudObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAddedItem()
        metadataQuery?.enableUpdates()
        
        didAddProgramObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.ProjectManagerDidAddProgram, object: nil, queue: nil) { (notification) in
            self.addedItem = notification.userInfo!["item"] as! ExplorerItem!
            self.showAddedItem()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        metadataQuery?.disableUpdates()
        
        if didAddProgramObserver != nil {
            NotificationCenter.default.removeObserver(didAddProgramObserver!)
            didAddProgramObserver = nil
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func loadLocalItems() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: ProjectManager.shared.localDocumentsUrl, includingPropertiesForKeys: nil, options: [])
            var items = [ExplorerItem]()
            for url in urls {
                if url.pathExtension == "nx" {
                    items.append(ExplorerItem(fileUrl: url))
                }
            }
            items.sort(by: { (item1, item2) -> Bool in
                return item1.createdAt < item2.createdAt
            })
            self.items = items
        } catch {
            // error
            items = nil
        }
        collectionView.reloadData()
    }
    
    private func setupCloud() {
        self.items = nil
        collectionView.reloadData()
        
        let query = NSMetadataQuery()
        metadataQuery = query
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K LIKE '*.nx'", NSMetadataItemFSNameKey)
        
        queryDidFinishGatheringObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: nil, queue: nil, using: { [weak self] (notification) in
            self?.cloudFileListReceived()
        })
        queryDidUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: nil, queue: nil, using: { [weak self] (notification) in
            self?.cloudFileListReceived()
        })
        query.start()
    }
    
    private func removeCloudObservers() {
        metadataQuery?.stop()
        if queryDidFinishGatheringObserver != nil {
            NotificationCenter.default.removeObserver(queryDidFinishGatheringObserver!)
            queryDidFinishGatheringObserver = nil
        }
        if queryDidUpdateObserver != nil {
            NotificationCenter.default.removeObserver(queryDidUpdateObserver!)
            queryDidUpdateObserver = nil
        }
    }
    
    private func cloudFileListReceived() {
        guard let query = metadataQuery else {
            return
        }
        
        query.disableUpdates()
        
        var items = [ExplorerItem]()
        for result in query.results as! [NSMetadataItem] {
            let url = result.value(forAttribute: NSMetadataItemURLKey) as! URL
            items.append(ExplorerItem(fileUrl: url))
        }
        items.sort(by: { (item1, item2) -> Bool in
            return item1.createdAt < item2.createdAt
        })
        self.items = items
        collectionView.reloadData()
        
        query.enableUpdates()
    }
        
    func showAddedItem() {
        if let addedItem = addedItem, items != nil {
            items!.append(addedItem)
            let indexPath = IndexPath(item: items!.count - 1, section: 0)
            collectionView.insertItems(at: [indexPath])
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            self.addedItem = nil
        }
    }
        
    @objc func onAddProjectTapped(_ sender: Any) {
        //[[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
        ProjectManager.shared.addNewProject { (error) in
            if let error = error {
                self.showAlert(withTitle: "Could Not Add New Project", message: error.localizedDescription, block: nil)
            }
        }
    }
    
    func onActionTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title:nil, message:nil, preferredStyle: .actionSheet)

        let isNormalFolder = true //(self.folder.folderType.integerValue == FolderTypeNormal);

        let addAction = UIAlertAction(title: "Add Folder", style: .default, handler: { [weak self] (action) in
            self?.onAddFolderTapped()
        })
        alert.addAction(addAction)

        let renameAction = UIAlertAction(title:"Rename this Folder", style: .default, handler: { [weak self] (action) in
            self?.onRenameFolderTapped()
        })
        renameAction.isEnabled = isNormalFolder
        alert.addAction(renameAction)

        let deleteAction = UIAlertAction(title:"Delete this Folder", style: .destructive, handler: { [weak self] (action) in
            self?.onDeleteFolderTapped()
        })
        deleteAction.isEnabled = isNormalFolder
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title:"Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)

        alert.popoverPresentationController?.barButtonItem = sender
        present(alert, animated: true, completion: nil)
    }
    
    func onAddFolderTapped() {
        //[[ModelManager sharedManager] createNewFolderInFolder:self.folder];
        //[self showAddedProject];
    }
    
    func onRenameFolderTapped() {
     /*  if (self.folder.isDefault.boolValue)
        {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example folders cannot be renamed." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
        ExplorerViewController __weak *weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please enter new folder name!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = weakSelf.folder.name;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        weakSelf.folder.name = ((UITextField *)alert.textFields[0]).text;
        weakSelf.navigationItem.title = weakSelf.folder.name;
        [[ModelManager sharedManager] saveContext];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        }*/
    }
    
    func onDeleteFolderTapped() {
/*    if (self.folder.children.count > 0)
    {
    [self showAlertWithTitle:@"Cannot delete folders with content" message:nil block:nil];
    }
    else
    {
    [[ModelManager sharedManager] deleteProject:self.folder];
    [self.navigationController popViewControllerAnimated:YES];
    }*/
    }
    
    func showEditor(fileUrl: URL) {
        AppController.shared().onProgramOpened()
        
        let document = ProjectDocument(fileURL: fileUrl)
        let vc = storyboard!.instantiateViewController(withIdentifier: "EditorView") as! EditorViewController
        vc.document = document
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func deleteItem(_ item: ExplorerItem, cell: ExplorerItemCell) {
        ProjectManager.shared.deleteProject(item: item) { (error) in
            if let error = error {
                self.showAlert(withTitle: "Could Not Delete Program", message: error.localizedDescription, block: nil)
            } else {
                if let index = self.items?.index(of: item) {
                    self.items?.remove(at: index)
                }
                if let indexPath = self.collectionView.indexPath(for: cell) {
                    self.collectionView.deleteItems(at: [indexPath])
                }
            }
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProjectCell", for: indexPath) as! ExplorerItemCell
        cell.item = self.items?[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    //MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items![indexPath.item]
        showEditor(fileUrl: item.fileUrl)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = collectionView.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right
        let numItemsPerLine = floor(width / 110)
        return CGSize(width: floor(width / numItemsPerLine), height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        UIMenuController.shared.menuItems = [
            UIMenuItem(title: "Rename...", action: #selector(ExplorerItemCell.renameItem)),
            UIMenuItem(title: "Delete...", action: #selector(ExplorerItemCell.deleteItem))
        ]
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if action == #selector(ExplorerItemCell.renameItem) || action == #selector(ExplorerItemCell.deleteItem) {
            return true
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    }
    
    //MARK: - ExplorerItemCellDelegate
    
    func explorerItemCell(_ cell: ExplorerItemCell, didSelectRename item: ExplorerItem) {
        print("rename i")
    }
    
    func explorerItemCell(_ cell: ExplorerItemCell, didSelectDelete item: ExplorerItem) {
        var message: String?
        if ProjectManager.shared.isCloudEnabled {
            message = "This file will be deleted from iCloud Drive and all your iCloud devices."
        }
        let alert = UIAlertController(title: "Do you really want to delete “\(item.name)”?", message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [unowned self] (action) in
            self.deleteItem(item, cell: cell)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
