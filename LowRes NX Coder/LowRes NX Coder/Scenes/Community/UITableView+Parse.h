//
//  UITableView+Parse.h
//  Pixels
//
//  Created by Timo Kloss on 23/2/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (Parse)

- (void)reloadDataAnimatedWithOldArray:(NSArray *)oldArray newArray:(NSArray *)newArray inSection:(NSInteger)section offset:(NSInteger)offset;

@end
