//
//  BorderedButton.m
//  Pixels
//
//  Created by Timo Kloss on 20/12/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import "BorderedButton.h"

@implementation BorderedButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 1;
    self.layer.cornerRadius = 4;
    self.contentEdgeInsets = UIEdgeInsetsMake(4, 6, 4, 6);
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    [self updateColor];
}

- (void)updateColor
{
    self.layer.borderColor = [self titleColorForState:self.state].CGColor;
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self updateColor];
}

@end
