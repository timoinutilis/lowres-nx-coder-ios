//
//  NSDate.m
//  Cu-Cu
//
//  Created by Duncan Campbell on 8/6/13.
//  Copyright (c) 2013 Meanwhile All rights reserved.
//

#import "NSDate+Utils.h"

@implementation NSDate (Utils)

- (NSDate *)dateWithoutTime
{
    NSDateComponents* comps = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self];
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (NSDate*)dateByAddingMonths:(int)months
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *monthComponent = [[NSDateComponents alloc] init];
    monthComponent.month = months;
    
    return [gregorian dateByAddingComponents:monthComponent toDate:self options:0];
}

- (NSDate*)dateByAddingDays:(int)days
{
    return [NSDate dateWithTimeInterval:days * 24 * 60 * 60 sinceDate:self];
}

- (NSDate*)dateByAddingHours:(int)hours
{
    return [NSDate dateWithTimeInterval:hours * 60 * 60 sinceDate:self];
}

- (bool)isBetweenDate:(NSDate*)firstDate andDate:(NSDate*)secondDate
{
    return ([self compare:firstDate] != NSOrderedAscending && [self compare:secondDate] == NSOrderedAscending);
}

- (bool)isEarlierThanDate:(NSDate*)date
{
    return self.timeIntervalSinceReferenceDate < date.timeIntervalSinceReferenceDate;
}

- (int)daysSinceFirstOfMonth
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    return (int)[currentCalendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self] - 1;
}

- (int)daysSinceFirstOfYear
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    return (int)[currentCalendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self] - 1;
}

- (BOOL)isInPast
{
    NSComparisonResult result = [[NSDate date] compare:self]; // comparing two dates
    return (result == NSOrderedDescending);
}

- (BOOL)isToday
{
    NSDate *today = [NSDate date].dateWithoutTime;
    NSDate *tomorrow = [today dateByAddingDays:1];
    return [self isBetweenDate:today andDate:tomorrow];
}

@end
