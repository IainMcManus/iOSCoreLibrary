//
//  NSDate+Extensions.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 7/01/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "NSDate+Extensions.h"

#ifdef __IPHONE_8_0
    #define ICL_DayCalendarUnit NSCalendarUnitDay
    #define ICL_MonthCalendarUnit NSCalendarUnitMonth
    #define ICL_YearCalendarUnit NSCalendarUnitYear
    #define ICL_WeekdayCalendarUnit NSCalendarUnitWeekday
    #define ICL_GregorianCalendar NSCalendarIdentifierGregorian
#elif __MAC_10_10
    #define ICL_DayCalendarUnit NSCalendarUnitDay
    #define ICL_MonthCalendarUnit NSCalendarUnitMonth
    #define ICL_YearCalendarUnit NSCalendarUnitYear
    #define ICL_WeekdayCalendarUnit NSCalendarUnitWeekday
    #define ICL_GregorianCalendar NSCalendarIdentifierGregorian
#else
    #define ICL_DayCalendarUnit NSDayCalendarUnit
    #define ICL_MonthCalendarUnit NSMonthCalendarUnit
    #define ICL_YearCalendarUnit NSYearCalendarUnit
    #define ICL_WeekdayCalendarUnit NSWeekdayCalendarUnit
    #define ICL_GregorianCalendar NSGregorianCalendar
#endif

@implementation NSDate (Extensions)

+ (NSCalendar*) gregorianCalendar {
    static NSCalendar* calendar = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:ICL_GregorianCalendar];
    });

    return calendar;
}

- (BOOL) isBetweenDates:(NSDate*) inStartDate endDate:(NSDate*) inEndDate {
    return (([self compare:inStartDate] != NSOrderedAscending) && ([self compare:inEndDate] != NSOrderedDescending));
}

- (NSDate*) dateFloor {
    NSDateComponents* dateComponents = [[NSDate gregorianCalendar] components:(ICL_DayCalendarUnit | ICL_MonthCalendarUnit | ICL_YearCalendarUnit) fromDate:self];
    
    return [[NSDate gregorianCalendar] dateFromComponents:dateComponents];
}

- (NSDate*) dateCeil {
    NSDateComponents* dateComponents = [[NSDate gregorianCalendar] components:(ICL_DayCalendarUnit | ICL_MonthCalendarUnit | ICL_YearCalendarUnit) fromDate:self];
    
    [dateComponents setHour:23];
    [dateComponents setMinute:59];
    [dateComponents setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:dateComponents];
}

- (NSDate*) startOfWeek {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_WeekdayCalendarUnit | ICL_YearCalendarUnit | ICL_MonthCalendarUnit | ICL_DayCalendarUnit fromDate:self];
    
    [components setDay:([components day] - ([components weekday] - 1))];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) endOfWeek {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_WeekdayCalendarUnit | ICL_YearCalendarUnit | ICL_MonthCalendarUnit | ICL_DayCalendarUnit fromDate:self];
    
    [components setDay:([components day] + (7 - [components weekday]))];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) startOfMonth {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_YearCalendarUnit | ICL_MonthCalendarUnit fromDate:self];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) endOfMonth {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_YearCalendarUnit | ICL_MonthCalendarUnit fromDate:self];
    
    NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:ICL_DayCalendarUnit inUnit:ICL_MonthCalendarUnit forDate:self];
    
    [components setDay:dayRange.length];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) startOfYear {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_YearCalendarUnit fromDate:self];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) endOfYear {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_YearCalendarUnit fromDate:self];
    
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
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_YearCalendarUnit | ICL_MonthCalendarUnit | ICL_DayCalendarUnit fromDate:self];
    
    NSInteger dayInMonth = [components day];
    
    // Update the components, initially setting the day in month to 0
    NSInteger newMonth = ([components month] - monthsToMove);
    [components setDay:1];
    [components setMonth:newMonth];
    
    // Determine the valid day range for that month
    NSDate* workingDate = [[NSDate gregorianCalendar] dateFromComponents:components];
    NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:ICL_DayCalendarUnit inUnit:ICL_MonthCalendarUnit forDate:workingDate];
    
    // Set the day clamping to the maximum number of days in that month
    [components setDay:MIN(dayInMonth, dayRange.length)];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

- (NSDate*) nextMonth {
    return [self nextMonth:1];
}

- (NSDate*) nextMonth:(NSUInteger) monthsToMove {
    NSDateComponents* components = [[NSDate gregorianCalendar] components:ICL_YearCalendarUnit | ICL_MonthCalendarUnit | ICL_DayCalendarUnit fromDate:self];
    
    NSInteger dayInMonth = [components day];
    
    // Update the components, initially setting the day in month to 0
    NSInteger newMonth = ([components month] + monthsToMove);
    [components setDay:1];
    [components setMonth:newMonth];
    
    // Determine the valid day range for that month
    NSDate* workingDate = [[NSDate gregorianCalendar] dateFromComponents:components];
    NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:ICL_DayCalendarUnit inUnit:ICL_MonthCalendarUnit forDate:workingDate];
    
    // Set the day clamping to the maximum number of days in that month
    [components setDay:MIN(dayInMonth, dayRange.length)];
    
    return [[NSDate gregorianCalendar] dateFromComponents:components];
}

@end
