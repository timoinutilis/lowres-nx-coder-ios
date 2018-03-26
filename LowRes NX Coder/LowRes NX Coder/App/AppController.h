//
//  AppController.h
//  Pixels
//
//  Created by Timo Kloss on 3/3/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, PurchaseState) {
    PurchaseStateUninitialized,
    PurchaseStateLoadingProducts,
    PurchaseStateProductsReady,
    PurchaseStateBusy
};

extern NSString *const PurchaseStateNotification;
extern NSString *const ShowPostNotification;
extern NSString *const UpgradeNotification;
extern NSString *const ImportProjectNotification;

@class TabBarController, HelpContent, RPPreviewViewController;

@interface TempProject : NSObject
@property NSString *name;
@property NSString *sourceCode;
@end

@interface AppController : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (weak) TabBarController *tabBarController;

@property (readonly) HelpContent *helpContent;

@property (readonly) PurchaseState purchaseState;
@property (readonly) BOOL isFullVersion;
@property (readonly) SKProduct *fullVersionProduct;
@property NSString *shouldShowPostId;
@property TempProject *shouldImportProject;
@property RPPreviewViewController *replayPreviewViewController;
@property (readonly) CFAbsoluteTime bootTime;

+ (AppController *)sharedController;

- (void)upgradeToFullVersion;

- (void)requestProducts;
- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchases;

- (BOOL)handleOpenURL:(NSURL *)url;

@end
