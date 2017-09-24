//
//  NSDate.h
//  Cu-Cu
//
//  Created by Duncan Campbell on 8/6/13.
//  Copyright (c) 2013 Meanwhile All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Utils)

- (NSDate *)dateWithoutTime;

- (NSDate*)dateByAddingMonths:(int)months;
- (NSDate*)dateByAddingDays:(int)days;
- (NSDate*)dateByAddingHours:(int)hours;

- (bool)isBetweenDate:(NSDate*)firstDate andDate:(NSDate*)secondDate;
- (bool)isEarlierThanDate:(NSDate*)date;

- (int)daysSinceFirstOfMonth;
- (int)daysSinceFirstOfYear;

- (BOOL)isInPast;
- (BOOL)isToday;

@end
