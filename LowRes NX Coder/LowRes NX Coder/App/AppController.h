//
//  AppController.h
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ShowPostNotification;
extern NSString *const ImportProjectNotification;

@class TabBarController, HelpContent;

@interface TempProject : NSObject
@property NSString *name;
@property NSString *sourceCode;
@end

@interface AppController : NSObject

@property (weak) TabBarController *tabBarController;

@property (readonly) HelpContent *helpContent;

@property NSString *shouldShowPostId;
@property TempProject *shouldImportProject;
@property (readonly) CFAbsoluteTime bootTime;

+ (AppController *)sharedController;

- (BOOL)handleOpenURL:(NSURL *)url;

@end
