//
//  LCCUser.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

extern NSString *const LowResNewsUserIDKey;

typedef NS_ENUM(int, LCCUserRole) {
    LCCUserRoleUser,
    LCCUserRoleModerator,
    LCCUserRoleAdmin
};

@interface LCCUser : APIObject

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *sessionToken;
@property (retain) NSString *about;
@property (retain) NSDate *lastPostDate;
@property (retain) NSDate *notificationsOpenedDate;
@property LCCUserRole role;

- (BOOL)isMe;
- (BOOL)isNewsUser;

- (BOOL)canDeleteAnyComment;
- (BOOL)canDeleteAnyPost;
- (BOOL)canResetAnyPassword;

@end
