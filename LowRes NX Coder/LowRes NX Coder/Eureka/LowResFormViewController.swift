//
//  LowResFormViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 5/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import UIKit

class LowResFormViewController: FormViewController {
    
    private var doneButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundView = nil;
        tableView.backgroundColor = AppStyle.tableBackgroundColor()
        
        doneButtonItem = navigationItem.rightBarButtonItem
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    var isBusy: Bool = false {
        didSet {
            navigationItem.leftBarButtonItem?.isEnabled = !isBusy
            view.isUserInteractionEnabled = !isBusy
            if isBusy {
                let activityView = UIActivityIndicatorView(activityIndicatorStyle: .white)
                activityView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                activityView.startAnimating()
                navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
            } else {
                navigationItem.rightBarButtonItem = doneButtonItem
            }
        }
    }
    
}
