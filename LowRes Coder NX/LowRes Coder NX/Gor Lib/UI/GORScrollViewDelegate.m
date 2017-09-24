//
//  GORScrollViewDelegate.m
//  Urban Ballr
//
//  Created by Timo Kloss on 4/12/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import "GORScrollViewDelegate.h"

@interface GORScrollViewDelegate ()
@property BOOL startedScrolling;
@end

@implementation GORScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.startedScrolling = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.disableBounceOnLimits && self.startedScrolling)
    {
        CGFloat offsetY = scrollView.contentOffset.y;
        if (offsetY <= 0 || offsetY >= scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom)
        {
            scrollView.bounces = NO;
        }
    }
    self.startedScrolling = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.disableBounceOnLimits)
    {
        scrollView.bounces = YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.disableBounceOnLimits && !decelerate)
    {
        scrollView.bounces = YES;
    }
}

@end
