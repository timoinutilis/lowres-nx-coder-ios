//
//  ExplorerViewController.swift
//  LowRes Coder NX
//
//  Created by Timo Kloss on 24/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class ExplorerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var folder: ExplorerItem?
    var items: [ExplorerItem]?
    
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
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        
        if let folder = folder {
            title = folder.name
        } else {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("documents:", documentsUrl)
            folder = ExplorerItem(fileUrl: documentsUrl)
        }
        
        loadItems()
    }
    
    func loadItems() {
        guard let folder = folder else {
            return
        }
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: folder.fileUrl, includingPropertiesForKeys: nil, options: [])
            var items = [ExplorerItem]()
            for url in urls {
                if url.pathExtension == "nx" {
                    items.append(ExplorerItem(fileUrl: url))
                }
            }
            self.items = items
        } catch {
            // error
            items = nil
        }
        collectionView.reloadData()
    }

    func onAddProjectTapped(_ sender: Any) {
        if folder!.isDefault {
            //showAlertWithTitle:@"Cannot add programs to example folders" message:nil block:nil];
        } else {
            //[[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
            
            if let folderUrl = folder?.fileUrl {
                let date = Date()
                let name = "New Program \(Int(date.timeIntervalSinceReferenceDate)).nx"
                let url = folderUrl.appendingPathComponent(name)
                showEditor(fileUrl: url, isNew: true)
            }
        }
    }
    
    func onActionTapped(_ sender: UIBarButtonItem) {
        if folder!.isDefault {
            //[self showAlertWithTitle:@"Example folders cannot be changed" message:nil block:nil];
        } else {
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
    
    func showEditor(fileUrl: URL, isNew: Bool) {
        AppController.shared().onProgramOpened()
        
        let document = ProjectDocument(fileURL: fileUrl)
        document.isNew = isNew
        
        let vc = storyboard!.instantiateViewController(withIdentifier: "EditorView") as! EditorViewController
        vc.document = document
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProjectCell", for: indexPath) as! ExplorerItemCell
        cell.item = self.items?[indexPath.item]
        return cell
    }
    
    //MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items![indexPath.item]
        showEditor(fileUrl: item.fileUrl, isNew: false)
    }
}
