//
//  CommLogInViewController.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORMenuTableViewController.h"

@interface CommLogInViewController : GORMenuTableViewController

+ (CommLogInViewController *)create;

@end


@interface CommLogInInputCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *textField;

- (void)setupAsUsername;
- (void)setupAsPasswordVerify:(BOOL)verify;

@end
