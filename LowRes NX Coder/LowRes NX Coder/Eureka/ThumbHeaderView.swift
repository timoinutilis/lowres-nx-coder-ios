//
//  ThumbHeaderView.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 13/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class ThumbHeaderView: UIView {

    @IBOutlet private weak var imageView: UIImageView!
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 0.5;
        imageView.layer.borderColor = UIColor(white: 0, alpha: 0.25).cgColor
    }
    
}
