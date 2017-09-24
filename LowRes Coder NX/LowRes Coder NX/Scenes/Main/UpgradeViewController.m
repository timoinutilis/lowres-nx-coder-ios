//
//  UpgradeViewController.m
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "UpgradeViewController.h"
#import "AppController.h"
#import "AppStyle.h"
#import <StoreKit/StoreKit.h>
#import "UIColor+Utils.h"

@interface UpgradeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *upgradeButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UILabel *upgradedLabel;
@end

@implementation UpgradeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.navigationController.presentingViewController)
    {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDoneTapped:)];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
    
    self.upgradedLabel.textColor = [AppStyle barColor];
    
    if ([SKPaymentQueue canMakePayments] && [AppController sharedController].purchaseState == PurchaseStateUninitialized)
    {
        [[AppController sharedController] requestProducts];
    }
    
    self.activityView.hidesWhenStopped = YES;
    [self updateView];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPurchaseStateChange:) name:PurchaseStateNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PurchaseStateNotification object:nil];
}

- (void)onPurchaseStateChange:(NSNotification *)notification
{
    [self updateView];
}

- (void)updateView
{
    if ([AppController sharedController].isFullVersion)
    {
        self.upgradedLabel.hidden = NO;
        [self.activityView stopAnimating];
        self.buttonsView.hidden = YES;
    }
    else
    {
        SKProduct *product = [AppController sharedController].fullVersionProduct;
        self.upgradedLabel.hidden = YES;
        
        switch ([AppController sharedController].purchaseState)
        {
            case PurchaseStateUninitialized:
                self.upgradeButton.enabled = NO;
                self.restoreButton.enabled = NO;
                [self.activityView stopAnimating];
                self.buttonsView.hidden = NO;
                break;
            case PurchaseStateLoadingProducts:
                self.upgradeButton.enabled = NO;
                self.restoreButton.enabled = NO;
                [self.activityView startAnimating];
                self.buttonsView.hidden = YES;
                break;
            case PurchaseStateProductsReady:
                [self updatePriceButton];
                self.upgradeButton.enabled = product != nil;
                self.restoreButton.enabled = product != nil;
                [self.activityView stopAnimating];
                self.buttonsView.hidden = NO;
                break;
            case PurchaseStateBusy:
                self.upgradeButton.enabled = NO;
                self.restoreButton.enabled = NO;
                [self.activityView startAnimating];
                self.buttonsView.hidden = YES;
                break;
        }
    }
}

- (void)updatePriceButton
{
    SKProduct *product = [AppController sharedController].fullVersionProduct;
    
    if (product)
    {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:product.price];
        
        NSString *title = [NSString stringWithFormat:@"Upgrade for %@", formattedPrice];
        self.upgradeButton.titleLabel.text = title;
        [self.upgradeButton setTitle:title forState:UIControlStateNormal];
    }
}

- (void)onDoneTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onUpgradeTapped:(id)sender
{
    SKProduct *product = [AppController sharedController].fullVersionProduct;
    [[AppController sharedController] purchaseProduct:product];
}

- (IBAction)onRestoreTapped:(id)sender
{
    [[AppController sharedController] restorePurchases];
}

@end
