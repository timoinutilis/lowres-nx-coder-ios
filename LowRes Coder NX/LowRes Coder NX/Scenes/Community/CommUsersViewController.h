//
//  CommUsersViewController.h
//  Pixels
//
//  Created by Timo Kloss on 25/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LCCUser;

typedef NS_ENUM(NSInteger, CommUsersMode) {
    CommUsersModeUndefined = 0,
    CommUsersModeFollowers,
    CommUsersModeFollowing
};

@interface CommUsersViewController : UITableViewController

- (void)setUser:(LCCUser *)user mode:(CommUsersMode)mode;

@end
