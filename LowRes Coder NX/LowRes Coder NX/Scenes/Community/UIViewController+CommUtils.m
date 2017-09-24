//
//  UIViewController+CommUtils.m
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "UIViewController+CommUtils.h"
#import "UIViewController+LowResCoder.h"
#import "CommunityModel.h"
#import "AppController.h"
#import "TabBarController.h"
#import "BlockerView.h"

const NSTimeInterval MAX_CACHE_AGE = 1 * 60 * 60;

@implementation UIViewController (CommUtils)

- (void)onGetProgramTappedWithPost:(LCCPost *)post
{
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
    }
     */
}

- (void)addProgramOfPost:(LCCPost *)post
{
    /*
    if (!post.isSourceCodeLoaded)
    {
        [BlockerView show];
    }
    
    [post loadSourceCodeWithCompletion:^(NSString *sourceCode, NSError *error) {
        
        [BlockerView dismiss];
        if (sourceCode)
        {
            Project *project = [[ModelManager sharedManager] createNewProjectInFolder:[ModelManager sharedManager].currentDownloadFolder];
            project.name = post.title;
            project.sourceCode = sourceCode;
            project.postId = post.objectId;
            
            LCCUser *currentUser = [CommunityModel sharedInstance].currentUser;
            
            if (!currentUser || ![post.user isEqualToString:currentUser.objectId])
            {
                [[CommunityModel sharedInstance] countDownloadPost:post];
            }
            
            BOOL root = (project.parent == [ModelManager sharedManager].rootFolder);
            
            if ([self isModal])
            {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [[AppController sharedController].tabBarController showExplorerAnimated:YES root:root];
                }];
            }
            else
            {
                [[AppController sharedController].tabBarController showExplorerAnimated:NO root:root];
            }
        }
        else
        {
            [self showAlertWithTitle:@"Could not download program" message:error.localizedDescription block:nil];
        }
        
    }];
     */
}

- (BOOL)isModal
{
    return self.navigationController.presentingViewController != nil;
}

@end
