//
//  NotificationView.h
//  Pixels
//
//  Created by Timo Kloss on 30/7/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationView : UIView

+ (void)showMessage:(NSString *)message block:(void (^)(void))block;

@end
