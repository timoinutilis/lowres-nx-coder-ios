//
//  SearchToolbar.m
//  Pixels
//
//  Created by Timo Kloss on 5/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "SearchToolbar.h"

@interface SearchToolbar() <UIToolbarDelegate, UITextFieldDelegate, UITraitEnvironment>

@property UITextField *findTextField;
@property UITextField *replaceTextField;
@property UIBarButtonItem *findFieldItem;
@property UIBarButtonItem *replaceFieldItem;

@property (weak) UITextField *activeTextField;

@end

@implementation SearchToolbar

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _findTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _findTextField.placeholder = @"Find Text";
        _findTextField.borderStyle = UITextBorderStyleRoundedRect;
        _findTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        _findTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _findTextField.delegate = self;
        _findTextField.delegate = self;
        
        _replaceTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
        _replaceTextField.placeholder = @"Replace With";
        _replaceTextField.borderStyle = UITextBorderStyleRoundedRect;
        _replaceTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        _replaceTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _replaceTextField.delegate = self;
        
        _findFieldItem = [[UIBarButtonItem alloc] initWithCustomView:_findTextField];
        UIBarButtonItem *findPrevItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"prev"] style:UIBarButtonItemStylePlain target:self action:@selector(onFindPrevTapped:)];
        findPrevItem.width = 26.0;
        UIBarButtonItem *findNextItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"next"] style:UIBarButtonItemStylePlain target:self action:@selector(onFindNextTapped:)];
        findNextItem.width = 26.0;
        _replaceFieldItem = [[UIBarButtonItem alloc] initWithCustomView:_replaceTextField];
        UIBarButtonItem *replaceItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"replace"] style:UIBarButtonItemStylePlain target:self action:@selector(onReplaceTapped:)];
        replaceItem.width = 26.0;
        
        self.items = @[_findFieldItem, findPrevItem, findNextItem, _replaceFieldItem, replaceItem];
        self.delegate = self;
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        _findTextField.clearButtonMode = UITextFieldViewModeAlways;
        _replaceTextField.clearButtonMode = UITextFieldViewModeAlways;
    }
    else
    {
        _findTextField.clearButtonMode = UITextFieldViewModeNever;
        _replaceTextField.clearButtonMode = UITextFieldViewModeNever;
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTop;
}

- (BOOL)dynamicLayout
{
    return (self.bounds.size.width < 414.0); // < iPhone 6+
}

- (void)layoutSubviews
{
    //TODO: iOS 11 uses auto layout for bar buttons
    
    CGFloat availableWidth = self.bounds.size.width - 150.0;
    if (![self dynamicLayout])
    {
        self.findFieldItem.width = availableWidth * 0.5;
        self.replaceFieldItem.width = availableWidth * 0.5;
    }
    else
    {
        if (self.activeTextField == _findTextField)
        {
            self.findFieldItem.width = availableWidth * 0.75;
        }
        else if (self.activeTextField)
        {
            self.findFieldItem.width = availableWidth * 0.25;
        }
        else
        {
            self.findFieldItem.width = availableWidth * 0.5;
        }

        if (self.activeTextField == _replaceTextField)
        {
            self.replaceFieldItem.width = availableWidth * 0.75;
        }
        else if (self.activeTextField)
        {
            self.replaceFieldItem.width = availableWidth * 0.25;
        }
        else
        {
            self.replaceFieldItem.width = availableWidth * 0.5;
        }
    }
    [super layoutSubviews];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
    if ([self dynamicLayout])
    {
        [self setNeedsLayout];
        [UIView animateWithDuration:0.3 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.text = [textField.text uppercaseString];
    self.activeTextField = nil;
    if ([self dynamicLayout])
    {
        [self setNeedsLayout];
        [UIView animateWithDuration:0.3 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self endEditing:YES];
    return NO;
}

- (void)onFindPrevTapped:(id)sender
{
    if (self.findTextField.text.length > 0)
    {
        [self endEditing:YES];
        [self.searchDelegate searchToolbar:self didSearch:self.findTextField.text backwards:YES];
    }
}

- (void)onFindNextTapped:(id)sender
{
    if (self.findTextField.text.length > 0)
    {
        [self endEditing:YES];
        [self.searchDelegate searchToolbar:self didSearch:self.findTextField.text backwards:NO];
    }
}

- (void)onReplaceTapped:(id)sender
{
    if (self.findTextField.text.length > 0 && self.replaceTextField.text.length > 0)
    {
        [self endEditing:YES];
        [self.searchDelegate searchToolbar:self didReplace:self.findTextField.text with:self.replaceTextField.text];
    }
}

@end
