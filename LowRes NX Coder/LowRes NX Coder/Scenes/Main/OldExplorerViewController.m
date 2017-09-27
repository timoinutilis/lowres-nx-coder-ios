//
//  ProjectExplorerViewController.m
//  Pixels
//
//  Created by Timo Kloss on 28/11/14.
//  Copyright (c) 2014 Inutilis Software. All rights reserved.
//

#import "ExplorerViewController.h"
#import "EditorViewController.h"
#import "AppController.h"
#import "CoachMarkView.h"
#import "UIViewController+LowResCoder.h"
#import "UICollectionView+Draggable.h"
#import "DraggableCollectionViewFlowLayout.h"
#import "AppStyle.h"

NSString *const CoachMarkIDAdd = @"CoachMarkIDAdd";

@interface ExplorerViewController ()  <UICollectionViewDelegate, UICollectionViewDataSource_Draggable, UITraitEnvironment>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property NSMutableArray *projects;
@property Project *addedProject;
@property Project *lastSelectedProject;
@property NSInteger firstUserProjectIndex;

@end

@implementation ExplorerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addProjectItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddProjectTapped:)];
    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"folder"] style:UIBarButtonItemStylePlain target:self action:@selector(onActionTapped:)];

    
    self.navigationItem.rightBarButtonItems = @[addProjectItem, actionItem];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.draggable = YES;
    
    DraggableCollectionViewFlowLayout *layout = (DraggableCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(140, 140);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    
    if (self.folder)
    {
        self.title = self.folder.name;
    }
    else
    {
        self.folder = [ModelManager sharedManager].rootFolder;
    }
    
    [self loadProjects];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddProject:) name:ModelManagerDidAddProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMoveProject:) name:ModelManagerDidMoveProjectNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerDidAddProjectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ModelManagerDidMoveProjectNotification object:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
    {
        self.navigationItem.backBarButtonItem = nil;
    }
    else
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[ModelManager sharedManager] setCurrentFolder:self.folder];
    
    if (self.lastSelectedProject)
    {
        if (self.lastSelectedProject.isDeleted || !self.lastSelectedProject.managedObjectContext)
        {
            [self loadProjects];
            self.addedProject = nil;
        }
        else
        {
            [self.collectionView reloadData];
        }
        self.lastSelectedProject = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.collectionView flashScrollIndicators];
    [self showAddedProject];
    
    AppController *app = [AppController sharedController];
    if (app.numProgramsOpened >= 3)
    {
        if ([app isUnshownInfoID:CoachMarkIDAdd])
        {
            [app onShowInfoID:CoachMarkIDAdd];
            CoachMarkView *coachMark = [[CoachMarkView alloc] initWithText:@"Tap the Plus button to create your first own program!" complete:nil];
            [coachMark setTargetNavBar:self.navigationController.navigationBar itemIndex:0];
            [coachMark show];
        }
    }
}

- (void)loadProjects
{
    if (self.folder.folderType.integerValue == FolderTypeRoot)
    {
        // default projects
        NSError *error;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Project"];
        request.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
        NSArray *defaultProjects = [[ModelManager sharedManager].temporaryContext executeFetchRequest:request error:&error];
        
        self.projects = [NSMutableArray arrayWithArray:defaultProjects];
        
        // add user projects
        [self.projects addObjectsFromArray:self.folder.children.array];
        
        self.firstUserProjectIndex = defaultProjects.count;
    }
    else
    {
        // user projects
        self.projects = [NSMutableArray arrayWithArray:self.folder.children.array];
        
        // parent folder represented by Null
        [self.projects insertObject:[NSNull null] atIndex:0];
        
        self.firstUserProjectIndex = 1;
    }
    
    [self.collectionView reloadData];
}

- (void)didAddProject:(NSNotification *)notification
{
    Project *project = notification.userInfo[@"project"];
    if (project.parent == self.folder)
    {
        self.addedProject = project;
    }
}

- (void)didMoveProject:(NSNotification *)notification
{
    Project *project = notification.userInfo[@"project"];
    if (project.parent == self.folder)
    {
        [self.projects addObject:project];
        [self.collectionView reloadData];
    }
}

- (void)onAddProjectTapped:(id)sender
{
    if (self.folder.isDefault.boolValue)
    {
        [self showAlertWithTitle:@"Cannot add programs to example folders" message:nil block:nil];
    }
    else
    {
        [[AppController sharedController] onShowInfoID:CoachMarkIDAdd];
        
        [[ModelManager sharedManager] createNewProjectInFolder:self.folder];
        [self showAddedProject];
    }
}

- (void)onActionTapped:(id)sender
{
    if (self.folder.isDefault.boolValue)
    {
        [self showAlertWithTitle:@"Example folders cannot be changed" message:nil block:nil];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak ExplorerViewController *weakSelf = self;
        
        BOOL isNormalFolder = (self.folder.folderType.integerValue == FolderTypeNormal);
        
        UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"Add Folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onAddFolderTapped];
        }];
        [alert addAction:addAction];
        
        UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"Rename this Folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [weakSelf onRenameFolderTapped];
        }];
        renameAction.enabled = isNormalFolder;
        [alert addAction:renameAction];
        
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete this Folder" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [weakSelf onDeleteFolderTapped];
        }];
        deleteAction.enabled = isNormalFolder;
        [alert addAction:deleteAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        
        alert.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onAddFolderTapped
{
    [[ModelManager sharedManager] createNewFolderInFolder:self.folder];
    [self showAddedProject];
}

- (void)onRenameFolderTapped
{
    if (self.folder.isDefault.boolValue)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Example folders cannot be renamed." message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        ExplorerViewController __weak *weakSelf = self;
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please enter new folder name!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = weakSelf.folder.name;
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            weakSelf.folder.name = ((UITextField *)alert.textFields[0]).text;
            weakSelf.navigationItem.title = weakSelf.folder.name;
            [[ModelManager sharedManager] saveContext];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onDeleteFolderTapped
{
    if (self.folder.children.count > 0)
    {
        [self showAlertWithTitle:@"Cannot delete folders with content" message:nil block:nil];
    }
    else
    {
        [[ModelManager sharedManager] deleteProject:self.folder];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)showAddedProject
{
    if (self.addedProject)
    {
        [self.projects addObject:self.addedProject];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.projects.count - 1 inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        
        self.addedProject = nil;
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.projects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = self.projects[indexPath.item];
    NSString *reuseIdentifier = ((id)project != [NSNull null] && project.folderType.integerValue == FolderTypeNone) ? @"ProjectCell" : @"FolderCell";
    ExplorerProjectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.project = project;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Project *project = self.projects[fromIndexPath.item];
    [self.projects removeObjectAtIndex:fromIndexPath.item];
    [self.projects insertObject:project atIndex:toIndexPath.item];
    
    NSMutableOrderedSet *childrenCopy = [self.folder.children mutableCopy];
    [childrenCopy removeObjectAtIndex:fromIndexPath.item - self.firstUserProjectIndex];
    [childrenCopy insertObject:project atIndex:toIndexPath.item - self.firstUserProjectIndex];
    self.folder.children = childrenCopy;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = self.projects[indexPath.item];
    return (id)project != [NSNull null];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Project *project1 = self.projects[indexPath.item];
    Project *project2 = self.projects[toIndexPath.item];
    return !project1.isDefault.boolValue && (id)project2 != [NSNull null] && !project2.isDefault.boolValue;
}

- (void)collectionView:(UICollectionView *)collectionView didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath intoItemAtIndexPath:(NSIndexPath *)intoIndexPath
{
    Project *project1 = self.projects[indexPath.item];
    Project *project2 = self.projects[intoIndexPath.item];
    return !project1.isDefault.boolValue
        && ((id)project2 == [NSNull null] || (project2.folderType.integerValue == FolderTypeNormal && !project2.isDefault.boolValue));
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath intoItemAtIndexPath:(NSIndexPath *)intoIndexPath
{
    Project *project = self.projects[fromIndexPath.item];
    Project *folder = self.projects[intoIndexPath.item];
    [self.projects removeObjectAtIndex:fromIndexPath.item];
    if ((id)folder == [NSNull null])
    {
        // to parent folder
        [[ModelManager sharedManager] moveProject:project toFolder:self.folder.parent];
    }
    else
    {
        // to selected folder
        [[ModelManager sharedManager] moveProject:project toFolder:folder];
        
        ExplorerProjectCell *cell = (ExplorerProjectCell *)[collectionView cellForItemAtIndexPath:intoIndexPath];
        [cell updateFolderContent];
    }
}

- (void)collectionView:(UICollectionView *)collectionView highlightItemAtIndexPath:(NSIndexPath *)indexPath enabled:(BOOL)enabled
{
    ExplorerProjectCell *cell = (ExplorerProjectCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.highlightedFolder = enabled;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = self.projects[indexPath.item];
    if ((id)project == [NSNull null])
    {
        // parent folder
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        self.lastSelectedProject = project;
        
        if (project.folderType.integerValue == FolderTypeNormal)
        {
            ExplorerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ExplorerView"];
            vc.folder = project;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else
        {
            [[AppController sharedController] onProgramOpened];
            
            EditorViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"EditorView"];
            vc.project = project;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	
}
*/

@end


@interface ExplorerProjectCell ()
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UIView *folderView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;
@end

@implementation ExplorerProjectCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    CALayer *imageLayer = self.previewImageView ? self.previewImageView.layer : self.folderView.layer;
    imageLayer.cornerRadius = 20;
    imageLayer.masksToBounds = YES;
}

- (void)setProject:(Project *)project
{
    _project = project;
    [self update];
}

- (void)update
{
    if ((id)self.project == [NSNull null])
    {
        // parent folder
        self.nameLabel.text = @"PARENT FOLDER";
        self.starImageView.hidden = YES;
        [self clearFolderContent];
        
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"parentfolder"]];
        CGSize folderSize = self.folderView.bounds.size;
        iconView.center = CGPointMake(folderSize.width * 0.5, folderSize.height * 0.5);
        [self.folderView addSubview:iconView];
    }
    else
    {
        self.nameLabel.text = self.project.name.uppercaseString;
        self.starImageView.hidden = !self.project.isDefault.boolValue;
        if (self.folderView)
        {
            // preview content of folder
            [self updateFolderContent];
        }
        else
        {
            self.previewImageView.image = [self imageWithSize:self.previewImageView.bounds.size forProject:self.project];
        }
    }
}

- (void)clearFolderContent
{
    for (UIView *subview in self.folderView.subviews)
    {
        [subview removeFromSuperview];
    }
}

- (void)updateFolderContent
{
    CGRect smallIconRect = CGRectMake(13, 13, 32, 32);

    [self clearFolderContent];
    
    NSMutableArray *images = [NSMutableArray array];
    for (Project *childProject in self.project.children)
    {
        if (childProject.folderType.integerValue == FolderTypeNone)
        {
            UIImage *image = [self imageWithSize:smallIconRect.size forProject:childProject];
            [images addObject:image];
        }
        if (images.count == 4)
        {
            break;
        }
    }
    if (images.count == 0)
    {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emptyfolder"]];
        CGSize folderSize = self.folderView.bounds.size;
        iconView.center = CGPointMake(folderSize.width * 0.5, folderSize.height * 0.5);
        [self.folderView addSubview:iconView];
    }
    else
    {
        for (int i = 0; i < images.count; i++)
        {
            UIImage *image = images[i];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.layer.cornerRadius = 6.0;
            imageView.layer.masksToBounds = YES;
            imageView.frame = smallIconRect;

            [self.folderView addSubview:imageView];
            if (i % 2 == 1)
            {
                smallIconRect.origin.x = 13.0;
                smallIconRect.origin.y += 38.0;
            }
            else
            {
                smallIconRect.origin.x += 38.0;
            }
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    CGFloat alpha = highlighted ? 0.5 : 1.0;
    if (self.previewImageView)
    {
        self.previewImageView.alpha = alpha;
    }
    else
    {
        self.folderView.alpha = alpha;
    }
}

- (void)setHighlightedFolder:(BOOL)highlightedFolder
{
    _highlightedFolder = highlightedFolder;
    CALayer *layer = self.folderView.layer;
    if (highlightedFolder)
    {
        layer.borderColor = [AppStyle darkTintColor].CGColor;
        layer.borderWidth = 4.0;
    }
    else
    {
        layer.borderWidth = 0.0;
    }
}

- (UIImage *)imageWithSize:(CGSize)size forProject:(Project *)project
{
    UIImage *image;
    if (project.iconData)
    {
        // program thumb
        image = [UIImage imageWithData:project.iconData];
    }
    else
    {
        // program default icon
        image = [UIImage imageNamed:@"icon_project"];
    }
    return image;
}

@end
