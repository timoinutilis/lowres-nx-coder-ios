//
//  UIImage+Utils.h
//  Urban Ballr
//
//  Created by Timo Kloss on 30/10/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

- (UIImage *)imageWithMaxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight fill:(BOOL)fill;
- (UIImage *)imageWithSize:(CGSize)size;
- (UIImage *)imageWithSize:(CGSize)size scale:(CGFloat)scale quality:(CGInterpolationQuality)quality;
- (UIImage *)imageAsTemplate;

@end
