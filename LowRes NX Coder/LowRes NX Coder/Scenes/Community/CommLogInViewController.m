//
//  CommLogInViewController.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "CommLogInViewController.h"
#import "CommunityModel.h"
#import "UIViewController+LowResCoder.h"
#import "GORCycleManager.h"
#import "AppController.h"
#import "ActionTableViewCell.h"
#import "AppStyle.h"

@interface CommLogInViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property CommLogInInputCell *logInUsernameCell;
@property CommLogInInputCell *logInPasswordCell;
@property ActionTableViewCell *logInButtonCell;
@property CommLogInInputCell *registerUsernameCell;
@property CommLogInInputCell *registerPasswordCell;
@property CommLogInInputCell *registerPasswordVerifyCell;
@property ActionTableViewCell *registerButtonCell;

@property (nonatomic) BOOL isBusy;
@property GORCycleManager *loginCycleManager;
@property GORCycleManager *signUpCycleManager;

@end

@implementation CommLogInViewController

+ (CommLogInViewController *)create
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Community" bundle:nil];
    CommLogInViewController *vc = (CommLogInViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CommLogInView"];
    return vc;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [AppStyle tableBackgroundColor];
    
    CommLogInViewController __weak *weakSelf = self;
    
    self.dynamicRowHeights = NO;

    self.logInUsernameCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInInputCell"];
    [self.logInUsernameCell setupAsUsername];
    self.logInPasswordCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInInputCell"];
    [self.logInPasswordCell setupAsPasswordVerify:NO];
    self.logInButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInButtonCell"];
    self.logInButtonCell.textLabel.text = @"Log In";
    
    self.loginCycleManager = [[GORCycleManager alloc] initWithFields:@[self.logInUsernameCell.textField, self.logInPasswordCell.textField] endBlock:^{ [weakSelf onLogInTapped]; }];
    
    self.registerUsernameCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInInputCell"];
    [self.registerUsernameCell setupAsUsername];
    self.registerPasswordCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInInputCell"];
    [self.registerPasswordCell setupAsPasswordVerify:NO];
    self.registerPasswordVerifyCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInInputCell"];
    [self.registerPasswordVerifyCell setupAsPasswordVerify:YES];
    self.registerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommLogInButtonCell"];
    self.registerButtonCell.textLabel.text = @"Register";

    self.signUpCycleManager = [[GORCycleManager alloc] initWithFields:@[self.registerUsernameCell.textField, self.registerPasswordCell.textField, self.registerPasswordVerifyCell.textField] endBlock:^{ [weakSelf onRegisterTapped]; }];

    [self setHeaderTitle:@"Log in with existing account" section:0];
    [self addCell:self.logInUsernameCell section:0];
    [self addCell:self.logInPasswordCell];
    [self addCell:self.logInButtonCell];
    [self setFooterTitle:@"If you forgot your password, please write to support@inutilis.com." section:0];
    
    [self setHeaderTitle:@"Create a new account" section:1];
    [self addCell:self.registerUsernameCell section:1];
    [self addCell:self.registerPasswordCell];
    [self addCell:self.registerPasswordVerifyCell];
    [self addCell:self.registerButtonCell];

    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    NSString *lastUserName = [storage objectForKey:UserDefaultsLogInKey];
    if (lastUserName)
    {
        self.logInUsernameCell.textField.text = lastUserName;
    }
}

- (void)setBusy:(BOOL)busy
{
    _isBusy = busy;
    self.cancelButton.enabled = !busy;
    [self.logInButtonCell setDisabled:busy wheel:NO];
    [self.registerButtonCell setDisabled:busy wheel:NO];
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isBusy)
    {
        [self.view endEditing:YES];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell == self.logInButtonCell)
        {
            [self onLogInTapped];
        }
        else if (cell == self.registerButtonCell)
        {
            [self onRegisterTapped];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)onRegisterTapped
{
    NSString *username = self.registerUsernameCell.textField.text;
    NSString *password = self.registerPasswordCell.textField.text;
    NSString *passwordVerify = self.registerPasswordVerifyCell.textField.text;
    
    if (username.length < 4)
    {
        [self showAlertWithTitle:(username.length == 0 ? @"Please enter a username!" : @"Please enter a longer username!") message:nil block:^{
            [self.registerUsernameCell.textField becomeFirstResponder];
        }];
        return;
    }
    if (password.length < 6)
    {
        [self showAlertWithTitle:(password.length == 0 ? @"Please enter a password!" : @"Please enter a longer password!") message:nil block:^{
            [self.registerPasswordCell.textField becomeFirstResponder];
        }];
        return;
    }
    if (passwordVerify.length == 0)
    {
        [self showAlertWithTitle:@"Please repeat your password!" message:nil block:^{
            [self.registerPasswordVerifyCell.textField becomeFirstResponder];
        }];
        return;
    }
    if (![password isEqualToString:passwordVerify])
    {
        [self showAlertWithTitle:@"Passwords do not match" message:nil block:^{
            self.registerPasswordCell.textField.text = @"";
            self.registerPasswordVerifyCell.textField.text = @"";
            [self.registerPasswordCell.textField becomeFirstResponder];
        }];
        return;
    }
    
    LCCUser *user = [[LCCUser alloc] init];
    user.username = username;
    user.password = password;
    
    [self setBusy:YES];
    [self.registerButtonCell setDisabled:YES wheel:YES];
    
    [[CommunityModel sharedInstance] signUpWithUser:user completion:^(BOOL succeeded, NSError *error) {
        [self setBusy:NO];
        if (succeeded)
        {
            [self loggedInWithUsername:username];
        }
        else
        {
            [self showAlertWithTitle:@"Could not register" message:error.presentableError.localizedDescription block:nil];
        }
    }];
}

- (void)onLogInTapped
{
    NSString *username = self.logInUsernameCell.textField.text;
    NSString *password = self.logInPasswordCell.textField.text;
    
    if (username.length == 0)
    {
        [self showAlertWithTitle:@"Please enter a username!" message:nil block:^{
            [self.logInUsernameCell.textField becomeFirstResponder];
        }];
        return;
    }
    if (password.length == 0)
    {
        [self showAlertWithTitle:@"Please enter a password!" message:nil block:^{
            [self.logInPasswordCell.textField becomeFirstResponder];
        }];
        return;
    }
    
    [self setBusy:YES];
    [self.logInButtonCell setDisabled:YES wheel:YES];
    
    [[CommunityModel sharedInstance] logInWithUsername:username password:password completion:^(BOOL succeeded, NSError *error) {
        [self setBusy:NO];
        if (succeeded)
        {
            [self loggedInWithUsername:username];
        }
        else if (error)
        {
            [self showAlertWithTitle:@"Could not log in" message:error.presentableError.localizedDescription block:nil];
        }
    }];
}

- (void)loggedInWithUsername:(NSString *)username
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setObject:username forKey:UserDefaultsLogInKey];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end


@implementation CommLogInInputCell

- (void)setupAsUsername
{
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textField.placeholder = @"Username";
}

- (void)setupAsPasswordVerify:(BOOL)verify
{
    self.textField.secureTextEntry = YES;
    self.textField.placeholder = verify ? @"Repeat password" : @"Password";
}

@end
