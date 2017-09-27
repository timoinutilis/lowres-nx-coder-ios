//
//  ShareViewController.h
//  Pixels
//
//  Created by Timo Kloss on 5/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORMenuTableViewController.h"

@class Project;

@interface ShareViewController : GORMenuTableViewController

@property Project *project;

+ (UIViewController *)createShareWithProject:(Project *)project;

@end

@interface ShareHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
