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
    
    @objc func onGetProgramTapped(post: LCCPost) {
        /*
        if ([[ModelManager sharedManager] hasProjectWithPostId:post.objectId])
        {
            id __weak weakSelf = self;
            [self showConfirmAlertWithTitle:@"Do you want to get another copy?" message:@"You already downloaded this program." block:^{
                [weakSelf addProgramOfPost:post];
            }];
        }
        else
        {
            [self addProgramOfPost:post];
        } */
        addProgram(of: post)
    }
    
    func addProgram(of post: LCCPost) {
        if !post.isSourceCodeLoaded {
            BlockerView.show()
        }
        
        post.loadSourceCode { (programData, error) in
            BlockerView.dismiss()
            
            if let programData = programData {
                ProjectManager.shared.addProject(name: post.title, programData: programData, completion: { (error) in
                    if let error = error {
                        self.showAlert(withTitle: "Could Not Save Program", message: error.localizedDescription, block: nil)
                    } else {
                        let currentUser = CommunityModel.sharedInstance().currentUser
                        if currentUser == nil || post.user != currentUser!.objectId {
                            CommunityModel.sharedInstance().countDownloadPost(post)
                        }
                        
                        if self.isModal {
                            self.presentingViewController?.dismiss(animated: true, completion: {
                                AppController.shared().tabBarController.showExplorer(animated: true, root: true)
                            })
                        } else {
                            AppController.shared().tabBarController.showExplorer(animated: false, root: true)
                        }
                    }
                })
            } else {
                self.showAlert(withTitle: "Could Not Download Program", message: error?.localizedDescription, block: nil)
            }
     
        }
    }
    
}
