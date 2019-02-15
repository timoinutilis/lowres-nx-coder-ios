//
//  AppController.m
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AppController.h"
#import "UIViewController+LowResCoder.h"
#import "HelpContent.h"
#import "TabBarController.h"

NSString *const ShowPostNotification = @"ShowPostNotification";
NSString *const UpgradeNotification = @"UpgradeNotification";
NSString *const ImportProjectNotification = @"ImportProjectNotification";


@implementation TempProject
@end


@implementation AppController

+ (AppController *)sharedController
{
    static AppController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"manual" withExtension:@"html" subdirectory:@"docs"];
        _helpContent = [[HelpContent alloc] initWithURL:url];
        
        _bootTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIViewController *vc = self.tabBarController.selectedViewController;
    if (vc.presentedViewController)
    {
        vc = vc.presentedViewController;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [vc presentViewController:alert animated:YES completion:nil];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    /*
    if ([[url scheme] isEqualToString:@"lowrescoder"])
    {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithParamsFromURL:url];
        NSString *postId = params[@"lccpost"];
        if (postId)
        {
            self.shouldShowPostId = postId;
            [[NSNotificationCenter defaultCenter] postNotificationName:ShowPostNotification object:self];
        }
        return YES;
    }
    else
    */
    if (url.isFileURL)
    {
        // load text file for new project
        NSError *error = nil;
        NSString *fileText = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        if (fileText)
        {
            NSString *name = url.lastPathComponent;
            if (url.pathExtension.length > 0)
            {
                name = [name substringToIndex:name.length - url.pathExtension.length - 1];
            }
            TempProject *tempProject = [[TempProject alloc] init];
            tempProject.name = name;
            tempProject.sourceCode = fileText;
            self.shouldImportProject = tempProject;
            [[NSNotificationCenter defaultCenter] postNotificationName:ImportProjectNotification object:self];
        }
        else
        {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }
    return NO;
}

@end
