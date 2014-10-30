//
//  NSDate+Extensions.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 7/01/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "NSDate+Extensions.h"

@implementation NSDate (Extensions)

+ (NSCalendar*) gregorianCalendar {
    static NSCalendar* calendar = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    });

    return calendar;
}

- (BOOL) isBetweenDates:(NSDate*) inStartDate endDate:(NSDate*) inEndDate {
    return (([self compare:inStartDate] != NSOrderedAscending) && ([self compare:inEndDate] != NSOrderedDescending));
}

- (NSDate*) dateFloor {
    NSDateComponents* dateComponents = [[NSDate gregorianCalendar] components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:self];
    
    return [[NSDate gregorianCalendar] dateFromComponents:dateComponents];
}

- (NSDate*) dateCeil {
    NSDateComponents* dateComponents = [[NSDate gregorianCalendar] components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:self];
    
    [dateComponents setHour:23];
    [dateComponents setMinute:59];
    [dateComponents setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:dateComponents];
}

- (NSDate*) startOfWeek {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    [components setDay:([components day] - ([components weekday] - 1))];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) endOfWeek {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    [components setDay:([components day] + (7 - [components weekday]))];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) startOfMonth {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) endOfMonth {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self];
    
    NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:self];
    
    [components setDay:dayRange.length];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) startOfYear {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSYearCalendarUnit fromDate:self];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) endOfYear {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSYearCalendarUnit fromDate:self];
    
    [components setDay:31];
    [components setMonth:12];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) previousDay {
    return [self dateByAddingTimeInterval:-86400];
}

- (NSDate*) nextDay {
    return [self dateByAddingTimeInterval:86400];
}

- (NSDate*) previousWeek {
    return [self dateByAddingTimeInterval:-(86400*7)];
}

- (NSDate*) nextWeek {
    return [self dateByAddingTimeInterval:+(86400*7)];
}

- (NSDate*) previousMonth {
    return [self previousMonth:1];
}

- (NSDate*) previousMonth:(NSUInteger) monthsToMove {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    NSInteger dayInMonth = [components day];
    
    // Update the components, initially setting the day in month to 0
    NSInteger newMonth = ([components month] - monthsToMove);
    [components setDay:1];
    [components setMonth:newMonth];
    
    // Determine the valid day range for that month
    NSDate* workingDate = [[NSDate gregorianCalendar] dateFromComponents:components];
    NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:workingDate];
    
    // Set the day clamping to the maximum number of days in that month
    [components setDay:MIN(dayInMonth, dayRange.length)];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) nextMonth {
    return [self nextMonth:1];
}

- (NSDate*) nextMonth:(NSUInteger) monthsToMove {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    NSInteger dayInMonth = [components day];
    
    // Update the components, initially setting the day in month to 0
    NSInteger newMonth = ([components month] + monthsToMove);
    [components setDay:1];
    [components setMonth:newMonth];
    
    // Determine the valid day range for that month
    NSDate* workingDate = [[NSDate gregorianCalendar] dateFromComponents:components];
    NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:workingDate];
    
    // Set the day clamping to the maximum number of days in that month
    [components setDay:MIN(dayInMonth, dayRange.length)];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

@end
