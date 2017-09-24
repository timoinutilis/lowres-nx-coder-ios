//
//  TextFieldTableViewCell.h
//  Pixels
//
//  Created by Timo Kloss on 1/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextFieldTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end
