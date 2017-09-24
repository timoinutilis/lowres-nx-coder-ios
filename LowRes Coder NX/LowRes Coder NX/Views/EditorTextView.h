//
//  EditorTextView.h
//  Pixels
//
//  Created by Timo Kloss on 25/2/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditorTextViewDelegate;

@interface EditorTextView : UITextView

@property (readonly) UIToolbar *keyboardToolbar;
@property (weak) id<EditorTextViewDelegate> editorDelegate;

+ (void)setTransferText:(NSString *)text;
+ (NSString *)transferText;

@end

@protocol EditorTextViewDelegate <NSObject>

- (void)editorTextView:(EditorTextView *)editorTextView didSelectHelpWithRange:(NSRange)range;

@end