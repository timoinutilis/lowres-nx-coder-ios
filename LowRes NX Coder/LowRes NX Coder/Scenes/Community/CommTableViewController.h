//
//  CommTableViewController.h
//  LowRes NX Coder
//
//  Created by Timo Kloss on 16/5/18.
//  Copyright © 2018 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommTableViewController : UITableViewController

- (void)onUserChanged:(NSNotification *)notification;

@end
