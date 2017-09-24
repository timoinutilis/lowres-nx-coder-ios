//
//  RadialGradientView.m
//  Pixels
//
//  Created by Timo Kloss on 26/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "RadialGradientView.h"

@implementation RadialGradientView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef cx = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();

    CGFloat radius = 150.0;
    
    CGRect radiusRect = CGRectMake(_point.x - radius, _point.y - radius, radius * 2.0, radius * 2.0);
    
    CGContextSaveGState(cx);
    CGContextAddRect(cx, self.bounds);
    CGContextAddRect(cx, radiusRect);
    CGContextEOClip(cx);
    CGContextFillRect(cx, self.bounds);
    CGContextRestoreGState(cx);
    
    
    CGFloat comps[] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0};
    CGFloat locs[] = {0.1, 0.5};
    CGGradientRef g = CGGradientCreateWithColorComponents(space, comps, locs, 2);
    
    CGContextClipToRect(cx, radiusRect);
    CGContextDrawRadialGradient(cx, g, _point, 0.0f, _point, radius * 2.0, 0);
    
    CGGradientRelease(g);
    CGColorSpaceRelease(space);
}

- (void)setPoint:(CGPoint)point
{
    _point = point;
    [self setNeedsDisplay];
}

@end
