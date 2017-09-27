//
//  GORMenuTableViewController.m
//  Urban Ballr
//
//  Created by Timo Kloss on 11/11/14.
//  Copyright (c) 2014 Gorilla Arm Ltd. All rights reserved.
//

#import "GORMenuTableViewController.h"

@interface GORMenuTableViewController ()
@property NSMutableArray *sections;
@property CGFloat verticalSpace;
@property NSMutableArray *spaceCells;
@end

@implementation GORMenuTableViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.dynamicRowHeights = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sections = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateSpace];
}

- (void)addCell:(UITableViewCell *)cell
{
    NSInteger section = self.sections.count;
    if (section > 0)
    {
        section--;
    }
    [self insertCell:cell section:section row:-1];
}

- (void)addCell:(UITableViewCell *)cell section:(NSInteger)section
{
    [self insertCell:cell section:section row:-1];
}

- (void)insertCell:(UITableViewCell *)cell section:(NSInteger)section row:(NSInteger)row
{
    GORMenuSection *sectionObj = [self sectionAt:section];
    if (row == -1)
    {
        [sectionObj.cells addObject:cell];
    }
    else
    {
        [sectionObj.cells insertObject:cell atIndex:row];
    }
    
    if ([cell isKindOfClass:[GORSpaceTableViewCell class]])
    {
        if (!self.spaceCells)
        {
            self.spaceCells = [NSMutableArray array];
        }
        [self.spaceCells addObject:cell];
    }
}

- (void)removeCell:(UITableViewCell *)cell section:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    [sectionObj.cells removeObject:cell];

    if ([cell isKindOfClass:[GORSpaceTableViewCell class]])
    {
        [self.spaceCells removeObject:cell];
    }
}

- (void)removeCellWithReuseIdentifier:(NSString *)reuseIdentifier section:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    for (int i = 0; i < sectionObj.cells.count; i++)
    {
        UITableViewCell *cell = sectionObj.cells[i];
        if ([cell.reuseIdentifier isEqualToString:reuseIdentifier])
        {
            [sectionObj.cells removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)setIsHidden:(BOOL)hidden section:(NSInteger)section
{
    GORMenuSection *sectionObj = [self sectionAt:section];
    sectionObj.isHidden = hidden;
}

- (void)setHeader:(UIView *)view section:(NSInteger)section
{
    GORMenuSection *sectionObj = [self sectionAt:section];
    sectionObj.header = view;
}

- (void)setHeaderTitle:(NSString *)text section:(NSInteger)section
{
    GORMenuSection *sectionObj = [self sectionAt:section];
    sectionObj.headerText = text;
}

- (void)setFooterTitle:(NSString *)text section:(NSInteger)section
{
    GORMenuSection *sectionObj = [self sectionAt:section];
    sectionObj.footerText = text;
}

- (void)updateSpace
{
    self.verticalSpace = 0.0;
    if (self.spaceCells)
    {
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        self.verticalSpace = MAX(0.0, self.tableView.frame.size.height - self.tableView.contentSize.height);
        [self.tableView reloadData];
    }
}

- (UITableViewCell *)cellWithReuseIdentifier:(NSString *)reuseIdentifier section:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    for (int i = 0; i < sectionObj.cells.count; i++)
    {
        UITableViewCell *cell = sectionObj.cells[i];
        if ([cell.reuseIdentifier isEqualToString:reuseIdentifier])
        {
            return cell;
        }
    }
    return nil;
}

- (GORMenuSection *)sectionAt:(NSInteger)index
{
    while (index >= self.sections.count)
    {
        [self.sections addObject:[[GORMenuSection alloc] init]];
    }
    return self.sections[index];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (CGFloat)actualRowHeight
{
    return (self.tableView.rowHeight > 0) ? self.tableView.rowHeight : 44.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    return sectionObj.isHidden ? 0 : sectionObj.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GORMenuSection *sectionObj = self.sections[indexPath.section];
    return sectionObj.cells[indexPath.row];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    return sectionObj.header;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    return sectionObj.headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    return sectionObj.footerText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.dynamicRowHeights)
    {
        GORMenuSection *sectionObj = self.sections[indexPath.section];
        UITableViewCell *cell = sectionObj.cells[indexPath.row];
        
        if (self.spaceCells && [cell isKindOfClass:[GORSpaceTableViewCell class]])
        {
            return floorf(self.verticalSpace / self.spaceCells.count);
        }
        
        if (![self.tableView respondsToSelector:@selector(separatorEffect)]) // iOS 8 check
        {
            // iOS 7 code
            CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
            return size.height;
        }
        
        // iOS 8 code
        return UITableViewAutomaticDimension;
    }
    
    return [self actualRowHeight];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.dynamicRowHeights)
    {
        GORMenuSection *sectionObj = self.sections[indexPath.section];
        UITableViewCell *cell = sectionObj.cells[indexPath.row];
        if (cell.bounds.size.height > 1)
        {
            return cell.bounds.size.height;
        }
        return [self actualRowHeight];
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    GORMenuSection *sectionObj = self.sections[section];
    if (sectionObj.header)
    {
        CGSize size = [sectionObj.header sizeThatFits:self.tableView.frame.size]; // maybe should be systemLayoutSizeFittingSize
        return size.height;
    }
    return UITableViewAutomaticDimension;
}

@end


@implementation GORSpaceTableViewCell

- (instancetype)init
{
    if (self = [super init])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

@end

@implementation GORMenuSection

- (instancetype)init
{
    if (self = [super init])
    {
        self.cells = [NSMutableArray array];
    }
    return self;
}

@end
