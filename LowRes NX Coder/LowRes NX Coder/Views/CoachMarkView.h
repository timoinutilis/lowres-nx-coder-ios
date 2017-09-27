//
//  HintView.h
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoachMarkView : UIView

- (instancetype)initWithText:(NSString *)text complete:(void (^)(void))block;

- (void)setTargetNavBar:(UINavigationBar *)navBar itemIndex:(int)index;
- (void)setTargetTabBar:(UITabBar *)tabBar itemIndex:(int)index;

- (void)show;
- (void)hide;

@end
