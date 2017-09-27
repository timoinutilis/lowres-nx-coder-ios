//
//  LimitedTextView.h
//  Pixels
//
//  Created by Timo Kloss on 2/12/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LimitedTextViewDelegate;

@interface LimitedTextView : UITextView

@property (nonatomic, weak) id<LimitedTextViewDelegate> limitDelegate;
@property (nonatomic) CGFloat heightLimit;
@property (nonatomic) BOOL hasOversize;
@property (nonatomic) BOOL limitEnabled;

@end


@protocol LimitedTextViewDelegate <NSObject>

- (void)textView:(LimitedTextView *)textView didChangeOversize:(BOOL)oversize;

@end
