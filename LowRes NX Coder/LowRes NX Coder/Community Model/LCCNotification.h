//
//  LCCNotification.h
//  Pixels
//
//  Created by Timo Kloss on 25/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

@class LCCUser, LCCPost;

typedef NS_ENUM(int, LCCNotificationType) {
    LCCNotificationTypeComment,
    LCCNotificationTypeLike,
    LCCNotificationTypeShare,
    LCCNotificationTypeFollow,
    LCCNotificationTypeReportComment
};

@interface LCCNotification : APIObject

@property (nonatomic) LCCNotificationType type;
@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSString *recipient;
@property (nonatomic, retain) NSString *post;
@property (nonatomic, retain) NSString *comment;

@property (nonatomic) LCCUser *senderObject;
@property (nonatomic) LCCPost *postObject;

@end
