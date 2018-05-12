//
//  CommSourceCodeViewController.m
//  Pixels
//
//  Created by Timo Kloss on 22/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommSourceCodeViewController.h"
#import "CommunityModel.h"
#import "LowRes_NX_Coder-Swift.h"
#import "AppStyle.h"
#import "ActivityView.h"

@interface CommSourceCodeViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property ActivityView *activityView;

@end

@implementation CommSourceCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [AppStyle editorColor];
    self.textView.backgroundColor = [AppStyle editorColor];
    self.textView.textColor = [AppStyle tintColor];
    self.textView.tintColor = [AppStyle brightColor];
    self.textView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.activityView = [ActivityView view];
    self.activityView.frame = self.view.bounds;
    [self.view addSubview:self.activityView];
    self.activityView.state = ActivityStateBusy;
    self.downloadButton.enabled = NO;
    
    [self.post loadSourceCodeWithCompletion:^(NSData *programData, NSError *error) {
        if (programData)
        {
            NSString *sourceCode = [[NSString alloc] initWithData:programData encoding:NSUTF8StringEncoding];
            
            self.activityView.state = ActivityStateReady;
            [self.activityView removeFromSuperview];
            self.textView.text = sourceCode;
            self.downloadButton.enabled = YES;
        }
        else
        {
            [self.activityView failWithMessage:error.presentableError.localizedDescription];
        }
    }];
}

- (IBAction)onGetTapped:(id)sender
{
    [self addProgramOf:self.post];
}

@end
