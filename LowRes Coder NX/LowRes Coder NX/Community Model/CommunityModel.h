//
//  CommunityModel.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCUser.h"
#import "LCCPost.h"
#import "LCCComment.h"
#import "LCCPostStats.h"
#import "LCCNotification.h"
#import "AFNetworking.h"

extern NSString *const CurrentUserChangeNotification;
extern NSString *const FollowsLoadNotification;
extern NSString *const FollowsChangeNotification;
extern NSString *const PostDeleteNotification;
extern NSString *const PostStatsChangeNotification;
extern NSString *const NotificationsUpdateNotification;
extern NSString *const NotificationsNumChangeNotification;

extern NSString *const UserDefaultsLogInKey;

typedef NS_ENUM(NSInteger, StatsType) {
    StatsTypeLike,
    StatsTypeDownload,
    StatsTypeComment
};

typedef void (^LCCResultBlock)(BOOL succeeded, NSError *error);
typedef void (^LCCUploadResultBlock)(NSURL *url, NSError *error);

@interface CommunityModel : NSObject

@property (nonatomic, readonly) AFHTTPSessionManager *sessionManager;
@property (nonatomic, readonly) NSMutableArray<LCCUser *> *follows;
@property (nonatomic, readonly) NSMutableArray <LCCNotification *> *notifications;
@property (nonatomic, readonly) BOOL isUpdatingNotifications;
@property (nonatomic, readonly) NSInteger numNewNotifications;
@property (nonatomic, readonly) LCCUser *currentUser;

+ (CommunityModel *)sharedInstance;

- (void)clearCache;

- (void)signUpWithUser:(LCCUser *)user completion:(LCCResultBlock)completion;
- (void)logInWithUsername:(NSString *)username password:(NSString *)password completion:(LCCResultBlock)completion;
- (void)logOut;
- (void)handleAPIError:(NSError *)error title:(NSString *)title viewController:(UIViewController *)vc;

- (void)onUserDataChanged;
- (void)updateCurrentUser;

- (void)followUser:(LCCUser *)user;
- (void)unfollowUser:(LCCUser *)user;
- (LCCUser *)userInFollowing:(LCCUser *)user;
- (void)likePost:(LCCPost *)post;
- (void)countDownloadPost:(LCCPost *)post;

- (void)loadNotifications;
- (void)onOpenNotifications;

- (void)uploadFileWithName:(NSString *)filename data:(NSData *)data completion:(LCCUploadResultBlock)block;

@end


@interface NSError (CommunityModel)

- (NSError *)presentableError;

@end
