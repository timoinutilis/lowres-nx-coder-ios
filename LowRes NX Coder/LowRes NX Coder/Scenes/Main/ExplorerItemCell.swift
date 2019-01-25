//
//  ExplorerProgramCell.swift
//  LowRes Coder NX
//
//  Created by Timo Kloss on 24/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

protocol ExplorerItemCellDelegate: class {
    func explorerItemCell(_ cell: ExplorerItemCell, didSelectRename item: ExplorerItem)
    func explorerItemCell(_ cell: ExplorerItemCell, didSelectDelete item: ExplorerItem)
}

class ExplorerItemCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var folderView: UIView!
    
    weak var delegate: ExplorerItemCellDelegate?
    
    var item: ExplorerItem? {
        didSet {
            if let item = item {
                nameLabel.text = item.name
                previewImageView.image = item.image
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let imageLayer = previewImageView != nil ? previewImageView.layer : folderView.layer
        imageLayer.cornerRadius = 2
        imageLayer.masksToBounds = true
        previewImageView.backgroundColor = AppStyle.mediumTintColor()
        
        shadowView.layer.cornerRadius = 3
        
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        nameLabel.layer.shadowOpacity = 1.0
        nameLabel.layer.shadowRadius = 0.0
    }
    
    @objc func renameItem(_ sender: Any?) {
        print("tapped rename", item!.fileUrl)
        if let delegate = delegate {
            delegate.explorerItemCell(self, didSelectRename: item!)
        }
    }
    
    @objc func deleteItem(_ sender: Any?) {
        print("tapped delete", item!.fileUrl)
        if let delegate = delegate {
            delegate.explorerItemCell(self, didSelectDelete: item!)
        }
    }

}
