//
//  FilledButton.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 12/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class FilledButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        clipsToBounds = true
        contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        setTitleColor(UIColor.white, for: .normal)
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        backgroundColor = tintColor
    }
    
}
