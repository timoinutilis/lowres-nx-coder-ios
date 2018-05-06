//
//  LowResFormViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 5/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class LowResFormViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = nil;
        tableView.backgroundColor = AppStyle.tableBackgroundColor()
    }

}
