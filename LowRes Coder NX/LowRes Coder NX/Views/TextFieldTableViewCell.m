//
//  TextFieldTableViewCell.m
//  Pixels
//
//  Created by Timo Kloss on 1/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "TextFieldTableViewCell.h"

@implementation TextFieldTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (self.iconImageView)
    {
        CALayer *layer = self.iconImageView.layer;
        layer.masksToBounds = YES;
        layer.cornerRadius = 6;
        layer.borderWidth = 0.5;
        layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
    }
}

@end
