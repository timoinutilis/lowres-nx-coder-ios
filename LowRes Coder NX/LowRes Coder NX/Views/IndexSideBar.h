//
//  IndexSideBar.h
//  Pixels
//
//  Created by Timo Kloss on 21/10/15.
//  Copyright © 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IndexSideBar : UIControl

@property (weak) UITextView *textView;
@property BOOL shouldUpdateOnTouch;

- (void)update;

@end


@interface IndexMarker : NSObject
@property NSString *label;
@property NSInteger line;
@property NSRange range;
@property CGFloat currentBarY;
@end
