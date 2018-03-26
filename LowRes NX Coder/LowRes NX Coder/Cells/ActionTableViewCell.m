//
//  ActionTableViewCell.m
//  Pixels
//
//  Created by Timo Kloss on 26/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "ActionTableViewCell.h"

@implementation ActionTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textLabel.textColor = self.contentView.tintColor;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    self.textLabel.textColor = self.contentView.tintColor;
}

- (void)setDisabled:(BOOL)disabled wheel:(BOOL)wheel
{
    if (disabled)
    {
        self.textLabel.textColor = [UIColor grayColor];
        if (wheel)
        {
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [indicator startAnimating];
            self.accessoryView = indicator;
        }
    }
    else
    {
        self.textLabel.textColor = self.contentView.tintColor;
        self.accessoryView = nil;
    }
    [self layoutIfNeeded];
}

@end
