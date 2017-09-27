//
//  ExplorerProgramCell.swift
//  LowRes Coder NX
//
//  Created by Timo Kloss on 24/9/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class ExplorerProgramCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var starImageView: UIImageView!
    @IBOutlet weak var folderView: UIView!
    
    var program: Project? {
        didSet {
            if let program = program {
                nameLabel.text = program.name
                previewImageView.image = program.image
                starImageView.isHidden = !program.isDefault
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let imageLayer = previewImageView != nil ? previewImageView.layer : folderView.layer
        imageLayer.cornerRadius = 4
        imageLayer.masksToBounds = true
    }
    
}
