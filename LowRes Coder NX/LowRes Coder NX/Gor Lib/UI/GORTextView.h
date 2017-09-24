//
//  GorillaTextView.h
//  MeanwhileConnect
//
//  Created by Timo Kloss on 15/10/14.
//  Copyright (c) 2014 Meanwhile. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GORTextViewLimit)
{
    GORTextViewLimitNone,
    GORTextViewLimitLetters,
    GORTextViewLimitWords
};

@interface GORTextView : UITextView <UITextViewDelegate>

@property (nonatomic) UIView *placeholderView;
@property (nonatomic) BOOL hidePlaceholderWhenFirstResponder;
@property (nonatomic) UILabel *counterLabel;
@property (nonatomic) NSString *counterFormat;
@property (nonatomic) GORTextViewLimit limitType;
@property (nonatomic) int limit;

@end
