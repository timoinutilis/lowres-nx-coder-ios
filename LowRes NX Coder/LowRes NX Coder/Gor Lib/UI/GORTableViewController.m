//
//  GORTableViewController.m
//  Urban Ballr
//
//  Created by Timo Kloss on 07/11/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import "GORTableViewController.h"

@interface GORTableViewController ()
@property BOOL startedScrolling;
@end

@implementation GORTableViewController

// duplicated code from GORScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.startedScrolling = YES;
}

// duplicated code from GORScrollViewDelegate
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

// duplicated code from GORScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.disableBounceOnLimits)
    {
        scrollView.bounces = YES;
    }
}

// duplicated code from GORScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.disableBounceOnLimits && !decelerate)
    {
        scrollView.bounces = YES;
    }
}

@end
