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
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        setTitleColor(UIColor.white, for: .normal)
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        backgroundColor = tintColor
    }
    
}
