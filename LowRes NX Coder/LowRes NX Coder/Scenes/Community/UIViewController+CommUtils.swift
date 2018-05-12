//
//  UIViewController+CommUtils.swift
//  LowRes NX Coder
//
//  Created by Timo Kloss on 11/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

import Foundation

extension UIViewController {
    
    @objc var isModal: Bool {
        return navigationController?.presentingViewController != nil
    }
    
    @objc func addProgram(of post: LCCPost) {
        if !post.isSourceCodeLoaded {
            BlockerView.show()
        }
        
        post.loadSourceCode { (programData, error) in
            if let programData = programData {
                post.loadImage(completion: { (imageData, _) in
                    // ignore image loading errors, just save program
                    ProjectManager.shared.addProject(originalName: post.title, programData: programData, imageData: imageData, completion: { (error) in
                        BlockerView.dismiss()
                        
                        if let error = error {
                            self.showAlert(withTitle: "Could Not Save Program", message: error.localizedDescription, block: nil)
                        } else {
                            CommunityModel.sharedInstance().countDownloadPost(post)
                            if self.isModal {
                                self.presentingViewController?.dismiss(animated: true, completion: {
                                    AppController.shared().tabBarController.showExplorer(animated: true, root: true)
                                })
                            } else {
                                AppController.shared().tabBarController.showExplorer(animated: false, root: true)
                            }
                        }
                    })
                })
            } else {
                BlockerView.dismiss()
                self.showAlert(withTitle: "Could Not Download Program", message: error?.localizedDescription, block: nil)
            }
        }
    }
    
    @objc func playProgram(of post: LCCPost) {
        view.endEditing(true)
        
        if !post.isSourceCodeLoaded {
            BlockerView.show()
        }
        
        post.loadSourceCode { (programData, error) in
            BlockerView.dismiss()
            
            if let programData = programData {
                let sourceCode = String(data: programData, encoding: .utf8)!
                
                let coreWrapper = CoreWrapper()
                let error = coreWrapper.compileProgram(sourceCode: sourceCode)
                
                if let error = error {
                    // show error
                    let alert = UIAlertController(title: error.message, message: error.line, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // start
                    let storyboard = UIStoryboard(name: "LowResNX", bundle: nil)
                    let vc = storyboard.instantiateInitialViewController() as! LowResNXViewController
                    vc.coreWrapper = coreWrapper
                    self.present(vc, animated: true, completion: nil)
                    
                    // count as download
                    CommunityModel.sharedInstance().countDownloadPost(post)
                }
            } else {
                self.showAlert(withTitle: "Could Not Load Program", message: error?.localizedDescription, block: nil)
            }
        }
    }
    
}
