//
//  ActivityView.h
//  Pixels
//
//  Created by Timo Kloss on 27/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ActivityState) {
    ActivityStateUnknown,
    ActivityStateReady,
    ActivityStateBusy,
    ActivityStateFailed
};

@interface ActivityView : UIView

@property (nonatomic) ActivityState state;

+ (instancetype)view;

- (void)failWithMessage:(NSString *)message;

@end
