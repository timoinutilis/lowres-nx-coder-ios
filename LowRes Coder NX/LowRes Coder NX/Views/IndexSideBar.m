//
//  IndexSideBar.m
//  Pixels
//
//  Created by Timo Kloss on 21/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "IndexSideBar.h"
#import "NSString+Utils.h"
#import "AppStyle.h"
#import "GORLabel.h"

static const CGFloat MARGIN = 3.0;

@interface IndexSideBar()
@property NSInteger numLines;
@property NSArray *markers;
@property IndexMarker *oldMarker;
@property UIView *highlight;
@property NSMutableArray *labels;
@property CGFloat startTouchY;
@end

@implementation IndexSideBar

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [AppStyle sideBarColor];
    self.alpha = 0.5;
    
    self.highlight = [[UIView alloc] init];
    self.highlight.backgroundColor = [AppStyle tintColor];
    self.highlight.alpha = 0.25;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat width = self.bounds.size.width;
    UIColor *rectColor = [AppStyle tintColor];
    
    CGRect markRect = CGRectMake(MARGIN, 0.0, width - 2 * MARGIN, 2.0);
    CGContextSetFillColorWithColor(context, rectColor.CGColor);
    for (IndexMarker *marker in self.markers)
    {
        markRect.origin.y = floor(marker.currentBarY);
        CGContextFillRect(context, markRect);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateBarPositions];
}

- (void)updateBarPositions
{
    CGFloat height = self.bounds.size.height - 2.0 - 2 * MARGIN;
    for (IndexMarker *marker in self.markers)
    {
        marker.currentBarY = MARGIN + marker.line * height / self.numLines;
    }
    [self setNeedsDisplay];
}

- (void)update
{
    /*
    NSString *text = self.textView.text;
    NSUInteger stringLength = text.length;
    NSMutableArray *markers = [NSMutableArray array];
    Scanner *scanner = [[Scanner alloc] init];
    
    NSUInteger numberOfLines, index;
    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
    {
        NSRange lineRange = [text lineRangeForRange:NSMakeRange(index, 0)];
        
        // check for labels
        NSRange findRange = [text rangeOfString:@":" options:0 range:lineRange];
        if (findRange.location != NSNotFound)
        {
            NSString *textLine = [text substringWithRange:lineRange];
            NSArray *tokens = [scanner tokenizeText:textLine];
            if (tokens && tokens.count >= 2)
            {
                Token *token1 = tokens[0];
                Token *token2 = tokens[1];
                if (token1.type == TTypeIdentifier && token2.type == TTypeSymColon)
                {
                    IndexMarker *marker = [[IndexMarker alloc] init];
                    marker.label = [[text substringWithRange:lineRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    marker.line = numberOfLines;
                    marker.range = lineRange;
                    [markers addObject:marker];
                }
            }
        }
        
        // next line
        index = NSMaxRange(lineRange);
    }
    self.numLines = numberOfLines;
    self.markers = markers;
    self.shouldUpdateOnTouch = NO;
    [self updateBarPositions];
     */
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event
{
    if (self.shouldUpdateOnTouch)
    {
        [self update];
    }
    [self showLabels];
    CGPoint point = [touch locationInView:self];
    self.startTouchY = point.y;
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event
{
    CGPoint point = [touch locationInView:self];
    [self touchedAtY:point.y];
    return YES;
}

- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event
{
    self.oldMarker = nil;
    [self unhighlight];
    [self hideLabels];
}

- (void)cancelTrackingWithEvent:(nullable UIEvent *)event
{
    self.oldMarker = nil;
    [self unhighlight];
    [self hideLabels];
}

- (void)touchedAtY:(CGFloat)touchY
{
    if (ABS(touchY - self.startTouchY) < 10.0)
    {
        // not moved enough
        return;
    }
    else
    {
        // unblock scrolling
        self.startTouchY = -100.0;
    }
    
    IndexMarker *bestMarker = nil;
    CGFloat bestDist = self.bounds.size.height;
    CGFloat dist;
    for (IndexMarker *marker in self.markers)
    {
        dist = ABS(marker.currentBarY - touchY);
        if (dist < 22.0 && (!bestMarker || dist < bestDist))
        {
            bestMarker = marker;
            bestDist = dist;
        }
    }
    
    CGFloat visibleHeight = self.textView.bounds.size.height - self.textView.contentInset.bottom;
    CGFloat maxOffset = MAX(0.0, self.textView.contentSize.height - visibleHeight);
    
    CGFloat scrollCenterY = -1.0;
    if (bestMarker)
    {
        if (bestMarker != self.oldMarker)
        {
            CGRect rect = [self.textView.layoutManager boundingRectForGlyphRange:bestMarker.range inTextContainer:self.textView.textContainer];
            rect.origin.y += self.textView.textContainerInset.top;
            scrollCenterY = rect.origin.y + rect.size.height * 0.5;

            rect.size.width -= 22.0;
            self.highlight.frame = rect;
            if (!self.highlight.superview)
            {
                [self.textView addSubview:self.highlight];
            }
            
            self.oldMarker = bestMarker;
        }
    }
    else
    {
        [self unhighlight];
        self.oldMarker = nil;
        
        CGFloat factor = (touchY - 22.0) / (self.bounds.size.height - 44.0);
        if (factor < 0.0) factor = 0.0;
        if (factor > 1.0) factor = 1.0;
        
        scrollCenterY = factor * self.textView.contentSize.height;
    }
    
    if (scrollCenterY != -1.0)
    {
        [self.textView setContentOffset:CGPointMake(0, MAX(MIN(floor(scrollCenterY - visibleHeight * 0.5), maxOffset), 0.0)) animated:NO];
    }
}

- (void)unhighlight
{
    if (self.highlight.superview)
    {
        [self.highlight removeFromSuperview];
    }
}

- (void)showLabels
{
    self.labels = [NSMutableArray arrayWithCapacity:self.markers.count];
    CGFloat lastBottom = 2.0;
    CGFloat lastX = 0.0;
    CGFloat lastY = 0.0;
    for (IndexMarker *marker in self.markers)
    {
        GORLabel *label = [[GORLabel alloc] init];
        label.userInteractionEnabled = NO;
        label.backgroundColor = [AppStyle barColor];
        label.insets = UIEdgeInsetsMake(0, -4.0, 0, -4.0);
        label.layer.cornerRadius = 4.0;
        label.clipsToBounds = YES;
        label.textColor = [AppStyle brightColor];
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = marker.label;
        [label sizeToFit];

        CGRect frame = label.frame;
        BOOL isFirstInLine = NO;
        if (marker.currentBarY > lastBottom)
        {
            frame.origin.x = ceil(-frame.size.width - 24.0);
            frame.origin.y = round(MAX(marker.currentBarY - frame.size.height * 0.5, lastBottom));
            isFirstInLine = YES;
        }
        else
        {
            frame.origin.x = floor(lastX - frame.size.width);
            frame.origin.y = round(lastY);
        }
        
        label.frame = [self.superview convertRect:frame fromView:self];
        lastX = frame.origin.x - 1.0;
        lastY = frame.origin.y;
        lastBottom = frame.origin.y + frame.size.height + 1.0;
        
        if (isFirstInLine || label.frame.origin.x >= 100.0)
        {
            [self.superview addSubview:label];
            [self.labels addObject:label];
        }
    }
}

- (void)hideLabels
{
    for (GORLabel *label in self.labels)
    {
        [label removeFromSuperview];
    }
    self.labels = nil;
}

@end


@implementation IndexMarker
@end
