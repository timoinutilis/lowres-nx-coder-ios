//
//  AppController.m
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "AppController.h"
#import "UIViewController+LowResCoder.h"
#import "NotificationView.h"
#import "NSMutableDictionary+Utils.h"
#import "HelpContent.h"
#import "TabBarController.h"
#import "CommunityModel.h"

NSString *const FullVersionProductID = @"fullversion";

NSString *const NumProgramsOpenedKey = @"NumProgramsOpened";

NSString *const PurchaseStateNotification = @"PurchaseStateNotification";
NSString *const ShowPostNotification = @"ShowPostNotification";
NSString *const UpgradeNotification = @"UpgradeNotification";
NSString *const ImportProjectNotification = @"ImportProjectNotification";


@implementation TempProject
@end


@implementation AppController

+ (AppController *)sharedController
{
    static AppController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    return sharedController;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _purchaseState = PurchaseStateUninitialized;
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"manual" withExtension:@"html" subdirectory:@"docs"];
        _helpContent = [[HelpContent alloc] initWithURL:url];
        
        _bootTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (BOOL)isFullVersion
{
    return YES;
//    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
//    return [storage boolForKey:FullVersionProductID];
}

- (void)upgradeToFullVersion
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setBool:YES forKey:FullVersionProductID];
    [storage synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:UpgradeNotification object:self];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIViewController *vc = self.tabBarController.selectedViewController;
    if (vc.presentedViewController)
    {
        vc = vc.presentedViewController;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)requestProducts
{
    self.purchaseState = PurchaseStateLoadingProducts;
    NSSet *productIdentifiers = [NSSet setWithObject:FullVersionProductID];
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products)
    {
        if ([product.productIdentifier isEqualToString:FullVersionProductID])
        {
            _fullVersionProduct = product;
        }
    }
    self.purchaseState = PurchaseStateProductsReady;
}

- (void)purchaseProduct:(SKProduct *)product
{
    self.purchaseState = PurchaseStateBusy;
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases
{
    self.purchaseState = PurchaseStateBusy;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing: {
                break;
            }
            case SKPaymentTransactionStateDeferred: {
                break;
            }
            case SKPaymentTransactionStateFailed: {
                [self showAlertWithTitle:@"Not upgraded" message:transaction.error.localizedDescription];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                self.purchaseState = PurchaseStateProductsReady;
                break;
            }
            case SKPaymentTransactionStatePurchased: {
                [self purchasedProductID:transaction.payment.productIdentifier];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                self.purchaseState = PurchaseStateProductsReady;
                break;
            }
            case SKPaymentTransactionStateRestored: {
                [self purchasedProductID:transaction.payment.productIdentifier];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                self.purchaseState = PurchaseStateProductsReady;
                break;
            }
            default:
                // For debugging
                NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    self.purchaseState = PurchaseStateProductsReady;
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    self.purchaseState = PurchaseStateProductsReady;
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    self.purchaseState = PurchaseStateProductsReady;
    if (!self.isFullVersion)
    {
        [self showAlertWithTitle:@"Not upgraded to full version" message:@"Maybe you upgraded with another App Store account?"];
    }
}

- (void)purchasedProductID:(NSString *)productID
{
    if ([productID isEqualToString:FullVersionProductID])
    {
        [self upgradeToFullVersion];
    }
}

- (void)setPurchaseState:(PurchaseState)purchaseState
{
    _purchaseState = purchaseState;
    [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseStateNotification object:self];
}

- (BOOL)isUnshownInfoID:(NSString *)infoId
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    return ![storage boolForKey:infoId];
}

- (void)onShowInfoID:(NSString *)infoId
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setBool:YES forKey:infoId];
}

- (NSInteger)numProgramsOpened
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    return [storage integerForKey:NumProgramsOpenedKey];
}

- (void)onProgramOpened
{
    NSUserDefaults *storage = [NSUserDefaults standardUserDefaults];
    [storage setInteger:([storage integerForKey:NumProgramsOpenedKey] + 1) forKey:NumProgramsOpenedKey];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    if ([[url scheme] isEqualToString:@"lowrescoder"])
    {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithParamsFromURL:url];
        NSString *postId = params[@"lccpost"];
        if (postId)
        {
            self.shouldShowPostId = postId;
            [[NSNotificationCenter defaultCenter] postNotificationName:ShowPostNotification object:self];
        }
        return YES;
    }
    else if (url.isFileURL)
    {
        // load text file for new project
        NSError *error = nil;
        NSString *fileText = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        if (fileText)
        {
            NSString *name = url.lastPathComponent;
            if (url.pathExtension.length > 0)
            {
                name = [name substringToIndex:name.length - url.pathExtension.length - 1];
            }
            TempProject *tempProject = [[TempProject alloc] init];
            tempProject.name = name;
            tempProject.sourceCode = fileText;
            self.shouldImportProject = tempProject;
            [[NSNotificationCenter defaultCenter] postNotificationName:ImportProjectNotification object:self];
        }
        else
        {
            NSLog(@"error: %@", error.localizedDescription);
        }
    }
    return NO;
}

@end
