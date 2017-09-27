//
//  HintView.m
//  Pixels
//
//  Created by Timo Kloss on 16/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CoachMarkView.h"
#import "RadialGradientView.h"
#import "AppController.h"
#import "TabBarController.h"

@interface CoachMarkView ()

@property RadialGradientView *radialGradientView;
@property UILabel *label;
@property UIImageView *pointerImageView;

@property (strong) void (^block)(void);
@property (weak) UINavigationBar *targetNavBar;
@property (weak) UITabBar *targetTabBar;
@property int targetItemIndex;
@property BOOL isHiding;

@end

@implementation CoachMarkView

- (instancetype)initWithText:(NSString *)text complete:(void (^)(void))block
{
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 320)])
    {
        self.block = block;
        
        RadialGradientView *rgView = [[RadialGradientView alloc] initWithFrame:self.bounds];
        rgView.alpha = 0.7;
        rgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:rgView];
        self.radialGradientView = rgView;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:24];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = text;
        label.userInteractionEnabled = NO;
        label.center = self.center;
        label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:label];
        self.label = label;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coach_pointer"]];
        imageView.userInteractionEnabled = NO;
        [self addSubview:imageView];
        self.pointerImageView = imageView;
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}

- (void)setTargetNavBar:(UINavigationBar *)navBar itemIndex:(int)index
{
    self.targetNavBar = navBar;
    self.targetItemIndex = index;
}

- (void)setTargetTabBar:(UITabBar *)tabBar itemIndex:(int)index
{
    self.targetTabBar = tabBar;
    self.targetItemIndex = index;
}

- (void)show
{
    self.alpha = 0.0;
    
    UIView *container = [AppController sharedController].tabBarController.view;
    [container addSubview:self];
    self.frame = container.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self layoutIfNeeded];
    
    [UIView animateWithDuration:1.0 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)hide
{
    if (!self.isHiding)
    {
        self.isHiding = YES;
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (self.block)
            {
                self.block();
                self.block = nil;
            }
            [self removeFromSuperview];
        }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGPoint targetCenter = [self targetCenter];
    self.radialGradientView.point = targetCenter;
    
    if (targetCenter.y < self.bounds.size.height * 0.5)
    {
        self.pointerImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        targetCenter.y += 60.0;
    }
    else
    {
        self.pointerImageView.transform = CGAffineTransformMakeScale(1.0, -1.0);
        targetCenter.y -= 64.0;
    }
    self.pointerImageView.center = targetCenter;
}

- (CGPoint)targetCenter
{
    if (self.targetTabBar)
    {
        CGRect rect = self.targetTabBar.frame;
        if (self.targetTabBar.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
        {
            CGFloat itemWidth = 110.0;
            return CGPointMake((rect.size.width - (self.targetItemIndex * itemWidth)) * 0.5, rect.origin.y + rect.size.height * 0.5);
        }
        else
        {
            CGFloat itemWidth = rect.size.width / self.targetTabBar.items.count;
            return CGPointMake((self.targetItemIndex + 0.5) * itemWidth, rect.origin.y + rect.size.height * 0.5);
        }
    }
    else
    {
        CGRect rect = self.targetNavBar.frame;
        return CGPointMake(rect.size.width - 25 - self.targetItemIndex * 50, rect.origin.y + rect.size.height * 0.5);
    }
    return CGPointZero;
}

- (void)onTap:(id)sender
{
    [self hide];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint target = [self targetCenter];
    if (ABS(point.x - target.x) < 44 && ABS(point.y - target.y) < 44)
    {
        self.userInteractionEnabled = NO;
        [self hide];
        return NO;
    }
    return [super pointInside:point withEvent:event];
}

@end
