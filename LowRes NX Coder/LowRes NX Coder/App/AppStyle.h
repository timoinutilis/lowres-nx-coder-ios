//
//  AppStyle.h
//  Pixels
//
//  Created by Timo Kloss on 14/4/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface AppStyle : NSObject

+ (void)setAppearance;

+ (UIColor *)barColor;
+ (UIColor *)tintColor;
+ (UIColor *)darkTintColor;
+ (UIColor *)brightTintColor;
+ (UIColor *)tableBackgroundColor;
+ (UIColor *)darkColor;
+ (UIColor *)brightColor;
+ (UIColor *)editorColor;
+ (UIColor *)warningColor;
+ (UIColor *)sideBarColor;

@end
NS_ASSUME_NONNULL_END
