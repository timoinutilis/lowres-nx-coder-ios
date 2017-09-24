//
//  CommStatusUpdateViewController.h
//  Pixels
//
//  Created by Timo Kloss on 26/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "GORMenuTableViewController.h"
#import "LCCPost.h"

@class LCCPostStats;

typedef void (^CommStatusUpdateBlock)(LCCPost *post, LCCPostStats *stats);

@interface CommStatusUpdateViewController : GORMenuTableViewController

+ (UIViewController *)createWithStoryboard:(UIStoryboard *)storyboard postType:(LCCPostType)type completion:(CommStatusUpdateBlock)block;

@end
