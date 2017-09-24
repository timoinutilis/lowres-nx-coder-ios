//
//  GorillaTextView.m
//  MeanwhileConnect
//
//  Created by Timo Kloss on 15/10/14.
//  Copyright (c) 2014 Meanwhile. All rights reserved.
//

#import "GORTextView.h"

@interface GORTextView ()
@end

@implementation GORTextView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.delegate = self;
    [self updateCounter];
    [self update];
}

- (void)setText:(NSString *)text
{
    super.text = text;
    [self update];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (self.limitType == GORTextViewLimitLetters)
    {
        return newText.length <= self.limit;
    }
    else if (self.limitType == GORTextViewLimitWords)
    {
        return [self countWordsInText:newText] <= self.limit;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self update];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (self.hidePlaceholderWhenFirstResponder)
    {
        self.placeholderView.hidden = YES;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.hidePlaceholderWhenFirstResponder)
    {
        self.placeholderView.hidden = (self.text.length > 0);
    }
}

- (void)update
{
    if (self.placeholderView)
    {
        if (self.hidePlaceholderWhenFirstResponder)
        {
            if (self.text && self.text.length > 0)
            {
                self.placeholderView.hidden = YES;
            }
        }
        else
        {
            self.placeholderView.hidden = (self.text && self.text.length > 0);
        }
    }
    if (self.limitType != GORTextViewLimitNone)
    {
        [self updateCounter];
    }
}

- (void)updateCounter
{
    NSUInteger count = 0;
    if (self.limitType == GORTextViewLimitLetters)
    {
        count = self.text.length;
    }
    else if (self.limitType == GORTextViewLimitWords)
    {
        count = [self countWordsInText:self.text];
    }
    
    if (self.counterLabel)
    {
        NSString *format = self.counterFormat ? self.counterFormat : @"%d";
        self.counterLabel.text = [NSString stringWithFormat:format, self.limit - count];
    }
}

- (int)countWordsInText:(NSString*)text
{
    int count = 0;
    NSUInteger len = text.length;
    
    for (int i = 0; i < len; i++)
    {
        unichar thisChar = [text characterAtIndex:i];
        unichar lastChar = (i > 0) ? [text characterAtIndex:i-1] : ' ';
        if (thisChar != ' ' && thisChar != '\n' && (lastChar == ' ' || lastChar == '\n'))
        {
            count++;
        }
    }
    return  count;
}

@end
