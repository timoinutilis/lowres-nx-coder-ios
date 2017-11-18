//
//  CommunityListViewController.h
//  Pixels
//
//  Created by Timo Kloss on 19/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GORTextView.h"
#import "LCCPost.h"

@class LCCUser, LCCPostStats;

typedef NS_ENUM(NSInteger, CommListMode) {
    CommListModeUndefined = 0,
    CommListModeProfile,
    CommListModeNews,
    CommListModeDiscover,
    CommListModeForum,
    CommListModeEssentials
};

@interface CommDetailViewController : UITableViewController

- (void)setUser:(LCCUser *)user mode:(CommListMode)mode;

@end



@interface CommProfileCell : UITableViewCell
@property (nonatomic) LCCUser *user;
- (void)toggleDetailSize;
@end

@interface CommInfoCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *infoTextLabel;
@end

@interface CommFilterCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
- (void)setMode:(CommListMode)mode;
- (void)setPostCategory:(LCCPostCategory)postCategory;
@end

@interface CommPostCell : UITableViewCell
@property (nonatomic, readonly) LCCPost *post;
@property (nonatomic, readonly) LCCUser *user;
- (void)setPost:(LCCPost *)post stats:(LCCPostStats *)stats user:(LCCUser *)user showName:(BOOL)showName;
- (void)setStats:(LCCPostStats *)stats;
@end
