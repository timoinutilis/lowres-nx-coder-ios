//
//  NotificationView.m
//  Pixels
//
//  Created by Timo Kloss on 30/7/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "NotificationView.h"
#import "AppStyle.h"

@interface NotificationView()
@property UILabel *label;
@property (strong) void (^block)(void);
@property BOOL isHiding;
@end

@implementation NotificationView

+ (void)showMessage:(NSString *)message block:(void (^)(void))block
{
    NotificationView *view = [[NotificationView alloc] initWithMessage:message block:block];
    [view show];
}

- (instancetype)initWithMessage:(NSString *)message block:(void (^)(void))block
{
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    CGRect frame = window.bounds;
    frame.size.height = 44 + statusBarHeight;
    
    if (self = [super initWithFrame:frame])
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [AppStyle tintColor];
        
        CGRect labelFrame = self.bounds;
        labelFrame.origin.x = 8;
        labelFrame.origin.y = statusBarHeight;
        labelFrame.size.width -= 16;
        labelFrame.size.height -= statusBarHeight;
        
        self.label = [[UILabel alloc] initWithFrame:labelFrame];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [AppStyle darkColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = [UIFont systemFontOfSize:14];
        self.label.numberOfLines = 0;
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.label];
        
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:recognizer];
        
        self.label.text = message;
        self.block = block;
    }
    return self;
}

- (void)show
{
    UIView *rootView = [[[UIApplication sharedApplication] delegate] window];
    [rootView addSubview:self];
    
    self.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeTranslation(0, 0);
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:3.6 target:self selector:@selector(onTimer:) userInfo:nil repeats:NO];
}

- (void)hide
{
    self.isHiding = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.transform = CGAffineTransformMakeTranslation(0, -self.bounds.size.height);
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        self.block = nil;
        
    }];
}

- (void)onTimer:(NSTimer *)timer
{
    if (!self.isHiding)
    {
        [self hide];
    }
}

- (void)onTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.block)
    {
        self.block();
        self.block = nil;
        if (!self.isHiding)
        {
            [self hide];
        }
    }
}

@end
