//
//  LimitedTextView.m
//  Pixels
//
//  Created by Timo Kloss on 2/12/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "LimitedTextView.h"

@interface LimitedTextView()
@property (nonatomic) CGFloat oldHeight;
@end

@implementation LimitedTextView

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat height = self.bounds.size.height;
    if (height != self.oldHeight)
    {
        self.hasOversize = (height >= self.heightLimit);
        [self.limitDelegate textView:self didChangeOversize:self.hasOversize];
        self.oldHeight = height;
    }
}

- (void)setLimitEnabled:(BOOL)limitEnabled
{
    _limitEnabled = limitEnabled;
    [self invalidateIntrinsicContentSize];
}

- (void)setHeightLimit:(CGFloat)heightLimit
{
    _heightLimit = heightLimit;
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    if (self.limitEnabled && size.height > self.heightLimit)
    {
        size.height = self.heightLimit;
    }
    return size;
}

@end
