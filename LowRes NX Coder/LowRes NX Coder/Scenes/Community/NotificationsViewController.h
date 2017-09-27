//
//  NotificationsViewController.h
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LCCNotification;

@interface NotificationsViewController : UITableViewController

@end

@interface NotificationCell : UITableViewCell
@property (nonatomic) LCCNotification *notification;
@property (nonatomic) BOOL isUnread;
@end
