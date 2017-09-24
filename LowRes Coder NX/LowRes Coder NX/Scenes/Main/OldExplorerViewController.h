//
//  ProjectExplorerViewController.h
//  Pixels
//
//  Created by Timo Kloss on 28/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Project;

@interface ExplorerViewController : UIViewController
@property Project *folder;
@end

@interface ExplorerProjectCell : UICollectionViewCell
@property (nonatomic) Project *project;
@property (nonatomic) BOOL highlightedFolder;
- (void)update;
- (void)updateFolderContent;
@end