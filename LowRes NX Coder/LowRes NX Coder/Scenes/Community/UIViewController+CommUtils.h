//
//  UIViewController+CommUtils.h
//  Pixels
//
//  Created by Timo Kloss on 31/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const NSTimeInterval MAX_CACHE_AGE;

@class LCCPost;

@interface UIViewController (CommUtils)

- (void)onGetProgramTappedWithPost:(LCCPost *)post;
- (BOOL)isModal;

@end
