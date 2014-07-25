//
//  NSDate+Extensions.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 7/01/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "NSDate+Extensions.h"

@implementation NSDate (Extensions)

- (BOOL) isBetweenDates:(NSDate*) inStartDate endDate:(NSDate*) inEndDate {
    return (([self compare:inStartDate] != NSOrderedAscending) && ([self compare:inEndDate] != NSOrderedDescending));
}

- (NSDate*) dateFloor {
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* dateComponents = [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:self];
    
    [dateComponents setHour:0];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    
    return [gregorian dateFromComponents:dateComponents];
}

- (NSDate*) dateCeil {
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* dateComponents = [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:self];
    
    [dateComponents setHour:23];
    [dateComponents setMinute:59];
    [dateComponents setSecond:59];
    
    return [gregorian dateFromComponents:dateComponents];
}

- (NSDate*) startOfWeek {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    NSUInteger dayOfWeek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self] weekday];
    
    [components setDay:([components day] - (dayOfWeek - 1))];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) endOfWeek {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    NSUInteger dayOfWeek = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self] weekday];
    
    [components setDay:([components day] + (7 - dayOfWeek))];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) startOfMonth {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) endOfMonth {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:self];
    
    NSRange dayRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:self];
    
    [components setDay:dayRange.length];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) previousWeek {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    [components setDay:([components day] - 7)];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) nextWeek {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    [components setDay:([components day] + 7)];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) previousMonth {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    NSInteger dayInMonth = [components day];

    // Update the components, initially setting the day in month to 0
    NSInteger newMonth = ([components month] - 1);
    [components setDay:0];
    [components setMonth:newMonth];
    
    // Determine the valid day range for that month
    NSDate* workingDate = [calendar dateFromComponents:components];
    NSRange dayRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:workingDate];

    // Set the day clamping to the maximum number of days in that month
    [components setDay:MIN(dayInMonth, dayRange.length)];
    
    return [calendar dateFromComponents:components];
}

- (NSDate*) nextMonth {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    NSInteger dayInMonth = [components day];
    
    // Update the components, initially setting the day in month to 0
    NSInteger newMonth = ([components month] + 1);
    [components setDay:0];
    [components setMonth:newMonth];
    
    // Determine the valid day range for that month
    NSDate* workingDate = [calendar dateFromComponents:components];
    NSRange dayRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:workingDate];
    
    // Set the day clamping to the maximum number of days in that month
    [components setDay:MIN(dayInMonth, dayRange.length)];
    
    return [calendar dateFromComponents:components];
}

@end
