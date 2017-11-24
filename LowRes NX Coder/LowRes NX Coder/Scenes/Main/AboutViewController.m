//
//  AboutViewController.m
//  Pixels
//
//  Created by Timo Kloss on 16/1/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AboutViewController.h"
#import "AppController.h"
#import "AppStyle.h"
#import "UIViewController+LowResCoder.h"
#import <MessageUI/MFMailComposeViewController.h>

@interface AboutViewController ()  <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;

@property NSArray *menuTitles;
@property NSArray *menuIndices;

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.versionLabel.text = [NSString stringWithFormat:@"Version %@", self.appVersion];
    self.copyrightLabel.textColor = [AppStyle barColor];
    
    self.menuTitles = @[
                        @"Full version",
                        @"Rate in App Store",
                        @"More from Inutilis",
                        @"Roadmap and Feedback",
                        @"Contact"];
    
    if ([AppController sharedController].isFullVersion)
    {
        self.menuIndices = @[/*@1, @3,*/ @4, @2];
    }
    else
    {
        self.menuIndices = @[@0, /*@1, @3,*/ @4, @2];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGFloat extraSpace = self.tableView.frame.size.height - self.tableView.contentSize.height;
    if (extraSpace < 0.0)
    {
        extraSpace = 0.0;
    }
    self.tableView.contentInset = UIEdgeInsetsMake(round(extraSpace * 0.3), 0, 0, 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuIndices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSNumber *index = self.menuIndices[indexPath.row];
    cell.textLabel.text = self.menuTitles[index.integerValue];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *index = self.menuIndices[indexPath.row];
    if (index.integerValue == 0)
    {
        [self performSegueWithIdentifier:@"Upgrade" sender:self];
    }
    else if (index.integerValue == 1)
    {
        // App Store
        NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/es/app/lowres-coder/id962117496?mt=8"];
        [[UIApplication sharedApplication] openURL:url];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (index.integerValue == 2)
    {
        // Web
        NSURL *url = [NSURL URLWithString:@"http://www.inutilis.com"];
        [[UIApplication sharedApplication] openURL:url];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (index.integerValue == 3)
    {
        // Future
        NSURL *url = [NSURL URLWithString:@"http://lowres.inutilis.com/future/"];
        [[UIApplication sharedApplication] openURL:url];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (index.integerValue == 4)
    {
        // Contact
        [self sendMail];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)sendMail
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.view.tintColor = [AppStyle tintColor];
        mailViewController.mailComposeDelegate = self;
        
        UIDevice *device = [UIDevice currentDevice];
        
        [mailViewController setToRecipients:@[@"support@inutilis.com"]];
        [mailViewController setSubject:@"LowRes Coder"];
        [mailViewController setMessageBody:[NSString stringWithFormat:@"\n\n\n\n%@\n%@ %@\nApp %@", device.model, device.systemName, device.systemVersion, self.appVersion] isHTML:NO];
        
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:support@inutilis.com"]];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)appVersion
{
    NSBundle *bundle = [NSBundle mainBundle];
    return [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
}

@end
