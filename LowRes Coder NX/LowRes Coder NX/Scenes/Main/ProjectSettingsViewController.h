//
//  ProjectSettingsViewController.h
//  Pixels
//
//  Created by Timo Kloss on 1/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProjectSettingsDelegate <NSObject>
- (void)projectSettingsDidChange;
@end

@class Project;

@interface ProjectSettingsViewController : UITableViewController

@property (weak) id <ProjectSettingsDelegate> delegate;
@property Project *project;
@property NSArray <UIImage *> *snapshotImages;

@end

@interface IconSelectorTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) NSArray <UIImage *> *images;
@end

@interface IconSelectorImageCollectionViewCell : UICollectionViewCell
@property (nonatomic) UIImage *image;
@end