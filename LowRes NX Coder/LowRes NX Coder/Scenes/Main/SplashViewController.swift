//
//  SplashViewController.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 24/11/17.
//  Copyright © 2017 Inutilis Software. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ProjectManager.shared.setup {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.showApp()
            }
        }
    }
    
    private func showApp() {
        if let window = view.window {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "AppStart") {
                window.rootViewController = vc
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = vc
                }, completion: nil)
            }
        }
    }
    
}
