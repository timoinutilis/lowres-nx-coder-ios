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
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var starImageView: UIImageView!
    @IBOutlet weak var folderView: UIView!
    
    weak var delegate: ExplorerItemCellDelegate?
    
    var item: ExplorerItem? {
        didSet {
            if let item = item {
                nameLabel.text = item.name
                previewImageView.image = item.image
                starImageView.isHidden = !item.isDefault
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let imageLayer = previewImageView != nil ? previewImageView.layer : folderView.layer
        imageLayer.cornerRadius = 4
        imageLayer.masksToBounds = true
    }
    
    @objc func renameItem(_ sender: Any?) {
        if let delegate = delegate {
            delegate.explorerItemCell(self, didSelectRename: item!)
        }
    }
    
    @objc func deleteItem(_ sender: Any?) {
        if let delegate = delegate {
            delegate.explorerItemCell(self, didSelectDelete: item!)
        }
    }

}
