//
//  CommEditUserViewController.h
//  Pixels
//
//  Created by Timo Kloss on 1/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORMenuTableViewController.h"

@interface CommEditUserViewController : GORMenuTableViewController

+ (CommEditUserViewController *)create;

@end


@interface CommEditUserInputCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end

@interface CommEditUserTextViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end