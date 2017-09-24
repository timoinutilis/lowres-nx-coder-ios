//
//  GORSeparatorView.m
//  Pixels
//
//  Created by Timo Kloss on 6/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORSeparatorView.h"

@implementation GORSeparatorView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    self.separatorColor = [UIColor blackColor];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint point = CGContextConvertPointToUserSpace(context, CGPointMake(1, 1));
    
    CGRect lineRect = rect;
    lineRect.size.height = point.y; // one screen pixel height
    CGContextSetFillColorWithColor(context, self.separatorColor.CGColor);
    CGContextFillRect(context, lineRect);
}

@end
