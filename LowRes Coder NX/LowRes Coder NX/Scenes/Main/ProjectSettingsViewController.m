//
//  ProjectSettingsViewController.m
//  Pixels
//
//  Created by Timo Kloss on 1/3/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "ProjectSettingsViewController.h"
#import "TextFieldTableViewCell.h"

typedef NS_ENUM(NSInteger, Section) {
    SectionName,
    SectionIconMode,
    SectionIconSelector,
    Section_count
};

@interface ProjectSettingsViewController() <UITextFieldDelegate, UICollectionViewDelegate>
@property NSString *name;
@property BOOL isIconLocked;
@property UIImage *iconImage;
@end

@implementation ProjectSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.name = self.project.name;
//    self.isIconLocked = self.project.isIconLocked.boolValue;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (IBAction)onDoneTapped:(id)sender
{
//    self.project.name = self.name;
//    self.project.isIconLocked = @(self.isIconLocked);
    if (self.iconImage)
    {
//        self.project.iconData = UIImagePNGRepresentation(self.iconImage);
    }
    [self.delegate projectSettingsDidChange];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancelTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

- (IBAction)onNameChanged:(UITextField *)textField
{
    self.name = textField.text;
}

- (UIImage *)currentIconImage
{
    if (self.iconImage)
    {
        return self.iconImage;
    }
//    if (self.project.iconData)
    {
//        return [UIImage imageWithData:self.project.iconData];
    }
    return [UIImage imageNamed:@"icon_project"];
}

#pragma mark - Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (   indexPath.section == SectionName
        || indexPath.section == SectionIconSelector)
    {
        return 88;
    }
    return tableView.rowHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return Section_count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case SectionName:
            return 1;
            
        case SectionIconMode:
            return 2;
            
        case SectionIconSelector:
            return 1;
    }
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case SectionName:
            return @"Program Name";

        case SectionIconMode:
            return @"Icon Mode";
            
        case SectionIconSelector:
            return @"Select Icon from Snapshots";
    }
    return nil;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == SectionIconSelector)
    {
        return @"These snapshots are from the last run of your program. Run it again to get new ones!";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case SectionName: {
            TextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextField" forIndexPath:indexPath];
            cell.textField.delegate = self;
            cell.textField.text = self.name;
            cell.iconImageView.image = [self currentIconImage];
            return cell;
        }
        
        case SectionIconMode: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Basic" forIndexPath:indexPath];
            if (indexPath.row == 0)
            {
                cell.textLabel.text = @"Update Automatically";
                cell.accessoryType = !self.isIconLocked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = @"Keep Current";
                cell.accessoryType = self.isIconLocked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
            return cell;
        }
            
        case SectionIconSelector:
        {
            IconSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IconSelector" forIndexPath:indexPath];
//            cell.images = self.project.temporarySnapshots;
            cell.collectionView.delegate = self;
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionIconMode)
    {
        self.isIconLocked = (indexPath.row == 1);
        [self updateIconModeCells];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.view endEditing:YES];
    }
}

- (void)updateIconModeCells
{
    // icon
    TextFieldTableViewCell *textFieldCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SectionName]];
    textFieldCell.iconImageView.image = [self currentIconImage];
    
    // mode
    UITableViewCell *cell;
    
    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:SectionIconMode]];
    cell.accessoryType = !self.isIconLocked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:SectionIconMode]];
    cell.accessoryType = self.isIconLocked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

#pragma mark - Icon Collection View

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    self.iconImage = self.project.temporarySnapshots[indexPath.item];
    self.isIconLocked = YES;
    [self updateIconModeCells];
}

@end


@interface IconSelectorTableViewCell() <UICollectionViewDataSource>
@end

@implementation IconSelectorTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.collectionView.dataSource = self;
}

- (void)setImages:(NSArray<UIImage *> *)images
{
    _images = images;
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IconSelectorImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Image" forIndexPath:indexPath];
    cell.image = self.images[indexPath.item];
    return cell;
}

@end


@interface IconSelectorImageCollectionViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation IconSelectorImageCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    CALayer *layer = self.imageView.layer;
    layer.masksToBounds = YES;
    layer.cornerRadius = 6;
    layer.borderWidth = 0.5;
    layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25].CGColor;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.imageView.alpha = highlighted ? 0.5 : 1.0;
}
@end
