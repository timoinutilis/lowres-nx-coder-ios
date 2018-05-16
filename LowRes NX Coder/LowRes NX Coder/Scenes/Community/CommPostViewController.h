//
//  CommPostViewController.h
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommTableViewController.h"

typedef NS_ENUM(NSInteger, CommPostMode) {
    CommPostModeUndefined = 0,
    CommPostModePost
};

@class LCCPost, LCCComment, LCCUser, LCCPostStats;

@interface CommPostViewController : CommTableViewController

- (void)setPost:(LCCPost *)post mode:(CommPostMode)mode;
- (void)setPost:(LCCPost *)post mode:(CommPostMode)mode commentId:(NSString *)commentId;

@end

@interface ProgramTitleCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *getProgramButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
- (void)setPost:(LCCPost *)post stats:(LCCPostStats *)stats user:(LCCUser *)user;
- (void)setStats:(LCCPostStats *)stats;
- (void)likeIt;
@end

@interface CommentCell : UITableViewCell
@property (weak) CommPostViewController *delegate;
- (void)setComment:(LCCComment *)comment user:(LCCUser *)user isHighlighted:(BOOL)isHighlighted;
@end

@interface WriteCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (void)reset;
@end
