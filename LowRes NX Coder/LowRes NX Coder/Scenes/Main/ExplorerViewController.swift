//
//  ExplorerViewController.swift
//  LowRes Coder NX
//
//  Created by Timo Kloss on 24/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class ExplorerViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, ExplorerItemCellDelegate, NSMetadataQueryDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var items: [ExplorerItem]?
    var addedItem: ExplorerItem?
    
    private var metadataQuery: NSMetadataQuery?
    private var didAddProgramObserver: Any?
    private var queryDidFinishGatheringObserver: Any?
    private var queryDidUpdateObserver: Any?
    private var willShowMenuObserver: Any?
    private var didHideMenuObserver: Any?
    private var isVisible: Bool = false
    private var unassignedItems = [URL: ExplorerItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppStyle.brightColor()
        
        let addProjectItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddProjectTapped))
//        let actionItem = UIBarButtonItem(image: UIImage(named:"folder"), style: .plain, target: self, action: #selector(onActionTapped))
        
//        navigationItem.rightBarButtonItems = [addProjectItem, actionItem]
        navigationItem.rightBarButtonItem = addProjectItem
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if ProjectManager.shared.isCloudEnabled {
            setupCloud()
        } else {
            loadLocalItems()
        }
        
        didAddProgramObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.ProjectManagerDidAddProgram, object: nil, queue: nil) { (notification) in
            let item: ExplorerItem! = notification.userInfo!["item"] as! ExplorerItem?
            self.unassignedItems[item.fileUrl] = item
            self.addedItem = item
            if self.isVisible {
                self.showAddedItem()
            }
        }
    }
    
    deinit {
        removeCloudObservers()
        if didAddProgramObserver != nil {
            NotificationCenter.default.removeObserver(didAddProgramObserver!)
            didAddProgramObserver = nil
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass == .regular {
            navigationItem.backBarButtonItem = nil
        } else {
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        showAddedItem()
        if let indexPaths = collectionView.indexPathsForSelectedItems, !indexPaths.isEmpty {
            // update cell of last used program
            collectionView.performBatchUpdates({
                self.collectionView.reloadItems(at: indexPaths)
            }, completion: { (finished) in
                self.metadataQuery?.enableUpdates()
            })
        } else {
            metadataQuery?.enableUpdates()
        }
        
        willShowMenuObserver = NotificationCenter.default.addObserver(
            forName: .UIMenuControllerWillShowMenu,
            object: nil,
            queue: nil
        ) { [weak self] (notification) in
            self?.metadataQuery?.disableUpdates()
        }
        didHideMenuObserver = NotificationCenter.default.addObserver(
            forName: .UIMenuControllerDidHideMenu,
            object: nil,
            queue: nil
        ) { [weak self] (notification) in
            self?.metadataQuery?.enableUpdates()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        metadataQuery?.disableUpdates()
        
        if willShowMenuObserver != nil {
            NotificationCenter.default.removeObserver(willShowMenuObserver!)
            willShowMenuObserver = nil
        }
        if didHideMenuObserver != nil {
            NotificationCenter.default.removeObserver(didHideMenuObserver!)
            didHideMenuObserver = nil
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
        updateFooter()
    }
    
    private func setupCloud() {
        self.items = nil
        collectionView.reloadData()
        updateFooter()
        
        activityView.startAnimating()
        
        let query = NSMetadataQuery()
        metadataQuery = query
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K LIKE '*.nx'", NSMetadataItemFSNameKey)
        query.delegate = self
        
        queryDidFinishGatheringObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query, queue: nil, using: { [weak self] (notification) in
            self?.activityView.stopAnimating()
            self?.cloudFileListReceived()
        })
        
        queryDidUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query, queue: nil, using: { [weak self] (notification) in
            if let userInfo = notification.userInfo {
                self?.updateFileList(addedItems: userInfo[NSMetadataQueryUpdateAddedItemsKey] as! [ExplorerItem],
                                     changedItems: userInfo[NSMetadataQueryUpdateChangedItemsKey] as! [ExplorerItem],
                                     removedItems: userInfo[NSMetadataQueryUpdateRemovedItemsKey] as! [ExplorerItem])
            }
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
        
        var items = query.results as! [ExplorerItem]
        items.sort(by: { (item1, item2) -> Bool in
            return item1.createdAt < item2.createdAt
        })
        self.items = items
        collectionView.reloadData()
        updateFooter()
        
        query.enableUpdates()
    }
    
    private func updateFileList(addedItems: [ExplorerItem], changedItems: [ExplorerItem], removedItems: [ExplorerItem]) {
        metadataQuery?.disableUpdates()
        
        var resultItems = items!
        
        var indexPathsToDelete = [IndexPath]()
        var indexPathsToInsert = [IndexPath]()
        var indexPathsToReload = [IndexPath]()
        
        for item in removedItems {
            if let originalIndex = items!.index(of: item) {
                indexPathsToDelete.append(IndexPath(item: originalIndex, section: 0))
                if let resultIndex = resultItems.index(of: item) {
                    resultItems.remove(at: resultIndex)
                }
            }
        }
        for item in changedItems {
            if let index = resultItems.index(of: item) {
                indexPathsToReload.append(IndexPath(item: index, section: 0))
                item.updateFromMetadata()
            }
        }
        for item in addedItems {
            if !resultItems.contains(item) {
                indexPathsToInsert.append(IndexPath(item: resultItems.count, section: 0))
                resultItems.append(item)
            }
        }
        if (!indexPathsToDelete.isEmpty || !indexPathsToInsert.isEmpty || !indexPathsToReload.isEmpty) {
            items = resultItems
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: indexPathsToDelete)
                collectionView.reloadItems(at: indexPathsToReload)
                collectionView.insertItems(at: indexPathsToInsert)
            }, completion: { (finished) in
                self.metadataQuery?.enableUpdates()
            })
        } else {
            metadataQuery?.enableUpdates()
        }
        updateFooter()
    }
    
    func showAddedItem() {
        if let addedItem = addedItem, items != nil {
            items!.append(addedItem)
            let indexPath = IndexPath(item: items!.count - 1, section: 0)
            collectionView.insertItems(at: [indexPath])
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            updateFooter()
            self.addedItem = nil
        }
    }
    
    private func updateFooter() {
        if let footerView = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionFooter, at: IndexPath(item: 0, section: 0)) {
            footerView.isHidden = items?.isEmpty ?? true
        }
    }
        
    @objc func onAddProjectTapped(_ sender: Any) {
        //[[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
        guard let items = items else {
            return
        }
        ProjectManager.shared.addNewProject(existingItems: items) { (error) in
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
        let document = ProjectDocument(fileURL: fileUrl)
        let vc = storyboard!.instantiateViewController(withIdentifier: "EditorView") as! EditorViewController
        vc.document = document
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func deleteItem(_ item: ExplorerItem) {
        metadataQuery?.disableUpdates()
        
        ProjectManager.shared.deleteProject(item: item) { (error) in
            if let error = error {
                self.metadataQuery?.enableUpdates()
                self.showAlert(withTitle: "Could Not Delete Program", message: error.localizedDescription, block: nil)
            } else {
                self.collectionView.performBatchUpdates({
                    if let index = self.items?.index(of: item) {
                        self.items?.remove(at: index)
                        self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                    }
                }, completion: { (finished) in
                    self.updateFooter()
                    self.metadataQuery?.enableUpdates()
                })
            }
        }
    }
    
    func renameItem(_ item: ExplorerItem, newName: String) {
        metadataQuery?.disableUpdates()
        
        ProjectManager.shared.renameProject(item: item, newName: newName) { (error) in
            if let error = error {
                self.metadataQuery?.enableUpdates()
                self.showAlert(withTitle: "Could Not Rename Program", message: error.localizedDescription, block: nil)
            } else {
                self.collectionView.performBatchUpdates({
                    if let index = self.items?.index(of: item) {
                        self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                    }
                }, completion: { (finished) in
                    self.metadataQuery?.enableUpdates()
                })
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
        footerView.isHidden = items?.isEmpty ?? true
        return footerView
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
        let alert = UIAlertController(title: "Rename “\(item.name)”", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.clearButtonMode = .always
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .no
            textField.spellCheckingType = .no
            textField.text = item.name
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (action) in
            let textField = alert.textFields!.first!
            if let name = textField.text?.trimmingCharacters(in: .whitespaces) {
                self.renameItem(item, newName: name)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func explorerItemCell(_ cell: ExplorerItemCell, didSelectDelete item: ExplorerItem) {
        var message: String?
        if ProjectManager.shared.isCloudEnabled {
            message = "This file will be deleted from iCloud Drive and all your iCloud devices."
        }
        let alert = UIAlertController(title: "Do you really want to delete “\(item.name)”?", message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [unowned self] (action) in
            self.deleteItem(item)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        if let pop = alert.popoverPresentationController {
            pop.sourceView = cell
            pop.sourceRect = cell.bounds
            pop.permittedArrowDirections = [.down, .up]
        }
    }
    
    //MARK: - NSMetadataQueryDelegate
    
    func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
        var resultItem: ExplorerItem
        let url = result.value(forAttribute: NSMetadataItemURLKey) as! URL
        if let item = unassignedItems[url] {
            unassignedItems.removeValue(forKey: url)
            resultItem = item
        } else {
            resultItem = ExplorerItem(fileUrl: url)
        }
        resultItem.metadataItem = result
        return resultItem
    }
    
}
