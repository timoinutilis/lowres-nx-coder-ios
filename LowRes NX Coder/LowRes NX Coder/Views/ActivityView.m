//
//  ActivityView.m
//  Pixels
//
//  Created by Timo Kloss on 27/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "ActivityView.h"
#import "AppStyle.h"

@interface ActivityView()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *failedView;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@end

@implementation ActivityView

+ (instancetype)view
{
    ActivityView *view = [[UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil] instantiateWithOwner:nil options:nil].firstObject;
    return view;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.indicatorView.color = [AppStyle barColor];
    self.indicatorView.hidesWhenStopped = YES;
    
    self.errorLabel.textColor = [AppStyle barColor];
    
    self.state = ActivityStateUnknown;
}

- (void)setState:(ActivityState)state
{
    _state = state;
    switch (state)
    {
        case ActivityStateUnknown:
        case ActivityStateReady:
            [self.indicatorView stopAnimating];
            self.failedView.hidden = YES;
            break;
            
        case ActivityStateBusy:
            [self.indicatorView startAnimating];
            self.failedView.hidden = YES;
            break;
            
        case ActivityStateFailed:
            [self.indicatorView stopAnimating];
            self.failedView.hidden = NO;
            break;
    }
    self.errorLabel.hidden = YES;
}

- (void)failWithMessage:(NSString *)message
{
    self.state = ActivityStateFailed;
    self.errorLabel.text = message;
    self.errorLabel.hidden = NO;
}

@end
