//
//  ICLScheduleHelper.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 31/07/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLScheduleHelper.h"
#import "NSDate+Extensions.h"

NSString* const kICLSchedule_StartDate = @"Schedule.StartDate";
NSString* const kICLSchedule_EndDate = @"Schedule.EndDate";
NSString* const kICLSchedule_Options = @"Schedule.Options";
NSString* const kICLSchedule_Type = @"Schedule.Type";

#ifdef __IPHONE_8_0
    #define ICL_DayCalendarUnit NSCalendarUnitDay
#elif __MAC_10_10
    #define ICL_DayCalendarUnit NSCalendarUnitDay
#else
    #define ICL_DayCalendarUnit NSDayCalendarUnit
#endif

@implementation ICLScheduleHelper

+ (NSArray*) generateScheduleDates:(NSDictionary*) repeatConfig
                          fromDate:(NSDate*) fromDate
                            toDate:(NSDate*) toDate {
    ScheduleType type = (ScheduleType)[repeatConfig[kICLSchedule_Type] integerValue];
    
    // just in case estNever is passed in we early out
    if (type == estNever) {
        return @[];
    }
    
    // from date is after the to date
    if ([fromDate compare:toDate] == NSOrderedDescending) {
        return @[];
    }
    
    NSDate* startDate = repeatConfig[kICLSchedule_StartDate];
    NSDate* endDate = toDate;
    NSArray* scheduleOptions = repeatConfig[kICLSchedule_Options];
    
    // ensure the end date is capped
    if (![repeatConfig[kICLSchedule_EndDate] isEqual:[NSNull null]]) {
        if ([toDate compare:repeatConfig[kICLSchedule_EndDate]] == NSOrderedDescending) {
            endDate = [repeatConfig[kICLSchedule_EndDate] copy];
        }
    }
    
    NSDate* generationStartDate = ([startDate compare:fromDate] == NSOrderedAscending) ? [fromDate copy] : [startDate copy];
    
    generationStartDate = [generationStartDate dateFloor];
    startDate = [startDate dateFloor];
    endDate = [endDate dateFloor];
    
    generationStartDate = [self findStartingDateForSchedule:generationStartDate
                                               scheduleType:type
                                                  startDate:startDate
                                                    endDate:endDate
                                            scheduleOptions:scheduleOptions];
    
    // start date is after the end date
    if ([generationStartDate compare:endDate] == NSOrderedDescending) {
        return @[];
    }
    
    NSArray* scheduleDates = [self buildScheduleDates:generationStartDate
                                         scheduleType:type
                                            startDate:startDate
                                              endDate:endDate
                                      scheduleOptions:scheduleOptions];
    
    return scheduleDates;
}

+ (NSArray*) buildScheduleDates:(NSDate*) searchDate
                   scheduleType:(ScheduleType) scheduleType
                      startDate:(NSDate*) startDate
                        endDate:(NSDate*) endDate
                scheduleOptions:(NSArray*) scheduleOptions {
    NSMutableArray* scheduleDates = [[NSMutableArray alloc] init];
    
    // always add the search date
    [scheduleDates addObject:searchDate];
    
    NSDate* nextDate = [self findNextDate:searchDate
                             scheduleType:scheduleType
                                startDate:startDate
                                  endDate:endDate
                          scheduleOptions:scheduleOptions];
    
    // add the next date until we pass the end date
    while (nextDate && ([nextDate compare:endDate] != NSOrderedDescending)) {
        [scheduleDates addObject:nextDate];
        
        nextDate = [self findNextDate:nextDate
                         scheduleType:scheduleType
                            startDate:startDate
                              endDate:endDate
                      scheduleOptions:scheduleOptions];
    }
    
    return scheduleDates;
}

+ (NSDate*) findNextDate:(NSDate*) currentDate
            scheduleType:(ScheduleType) scheduleType
               startDate:(NSDate*) startDate
                 endDate:(NSDate*) endDate
         scheduleOptions:(NSArray*) scheduleOptions {
    NSDateComponents* startComponents =  [[NSDate gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:startDate];
    NSDateComponents* currentComponents = [[NSDate gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:currentDate];
    
    NSDate* nextDate = nil;
    
    switch (scheduleType) {
        case estDaily: {
            NSInteger lowestDeltaDays = 7;
            
            // find the closest next weekday
            for (NSNumber* rawDayOfWeek in scheduleOptions) {
                NSInteger requiredDayOfWeek = [rawDayOfWeek integerValue] + 1;
                NSInteger weekdayDelta = 7;
                
                // If the required weekday is after the search weekday then advance to that weekday
                if (requiredDayOfWeek > [currentComponents weekday]) {
                    weekdayDelta = requiredDayOfWeek - [currentComponents weekday];
                } // If the required weekday is before the search weekday then advance to that weekday wrapping into the next week
                else if (requiredDayOfWeek < [currentComponents weekday]) {
                    weekdayDelta = (7 - [currentComponents weekday]) + requiredDayOfWeek;
                }
                
                lowestDeltaDays = MIN(weekdayDelta, lowestDeltaDays);
            }
            
            [currentComponents setDay:[currentComponents day] + lowestDeltaDays];
        }
            break;
            
        case estWeekly: {
            [currentComponents setDay:[currentComponents day] + 7];
        }
            break;
            
        case estFortnightly: {
            [currentComponents setDay:[currentComponents day] + 14];
        }
            break;
            
        case estMonthly: {
            // advance to the next month, setting the day to 1 to ensure we handle day in month shifting correctly
            [currentComponents setDay:1];
            [currentComponents setMonth:[currentComponents month] + 1];
            nextDate = [[NSDate gregorianCalendar] dateFromComponents:currentComponents];
            
            // Snap the day to be in the valid range for that month
            NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:nextDate];
            [currentComponents setDay:MIN([startComponents day], dayRange.length)];
        }
            break;
            
        case estQuarterly: {
            // advance to the next quarter, setting the day to 1 to ensure we handle day in month shifting correctly
            [currentComponents setDay:1];
            [currentComponents setMonth:[currentComponents month] + 3];
            nextDate = [[NSDate gregorianCalendar] dateFromComponents:currentComponents];
            
            // Snap the day to be in the valid range for that month
            NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:nextDate];
            [currentComponents setDay:MIN([startComponents day], dayRange.length)];
        }
            break;
            
        case estAnnually: {
            // advance to the next year, setting the day to 1 to ensure we handle day in month shifting correctly
            [currentComponents setDay:1];
            [currentComponents setYear:[currentComponents year] + 1];
            nextDate = [[NSDate gregorianCalendar] dateFromComponents:currentComponents];
            
            // Snap the day to be in the valid range for that month
            NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:nextDate];
            [currentComponents setDay:MIN([startComponents day], dayRange.length)];
        }
            break;
            
        default:
            break;
    }
    
    nextDate = [[NSDate gregorianCalendar] dateFromComponents:currentComponents];
    
    return nextDate;
}

+ (NSDate*) findStartingDateForSchedule:(NSDate*) searchDate
                           scheduleType:(ScheduleType) scheduleType
                              startDate:(NSDate*) startDate
                                endDate:(NSDate*) endDate
                        scheduleOptions:(NSArray*) scheduleOptions {
    NSDateComponents* startComponents =  [[NSDate gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:startDate];
    NSDateComponents* searchComponents = [[NSDate gregorianCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:searchDate];
    
    NSDateComponents* resultComponents = [startComponents copy];
    
    switch (scheduleType) {
        case estDaily: {
            NSInteger lowestDeltaDays = 7;
            
            // find the closest next weekday
            for (NSNumber* rawDayOfWeek in scheduleOptions) {
                NSInteger requiredDayOfWeek = [rawDayOfWeek integerValue] + 1;
                NSInteger weekdayDelta = 7;
                
                // If the required weekday is after the search weekday then advance to that weekday
                if (requiredDayOfWeek > [searchComponents weekday]) {
                    weekdayDelta = requiredDayOfWeek - [searchComponents weekday];
                } // If the required weekday is before the search weekday then advance to that weekday wrapping into the next week
                else if (requiredDayOfWeek < [searchComponents weekday]) {
                    weekdayDelta = (7 - [searchComponents weekday]) + requiredDayOfWeek;
                } // The required weekday and the search weekday are the same
                else {
                    // if the start and end date are different then we can directly use the search date and exit early
                    if (![startDate isEqualToDate:searchDate]) {
                        lowestDeltaDays = 0;
                        break;
                    }
                }
                
                lowestDeltaDays = MIN(weekdayDelta, lowestDeltaDays);
            }
            
            resultComponents = [searchComponents copy];
            [resultComponents setDay:[resultComponents day] + lowestDeltaDays];
            
            NSDate* resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            return resultDate;
        }
            break;
            
        case estWeekly: {
            NSInteger requiredDayOfWeek = edsoSunday;
            
            // if the schedule options are present and have a value then use that
            if (scheduleOptions && ([scheduleOptions count] > 0)) {
                requiredDayOfWeek = [[scheduleOptions firstObject] integerValue] + 1;
            } // otherwise determine the day of the week from the start date
            else {
                requiredDayOfWeek = [startComponents weekday];
            }
            
            BOOL startAndSearchSame = [startDate isEqualToDate:searchDate];
            
            // If the required weekday is after the starting weekday then advance to that weekday
            if (requiredDayOfWeek > [startComponents weekday]) {
                NSInteger weekdayDelta = requiredDayOfWeek - [startComponents weekday];
                
                [resultComponents setDay:[resultComponents day] + weekdayDelta];
                
                startDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            } // If the required weekday is before the starting weekday then advance to that weekday wrapping into the next week
            else if (requiredDayOfWeek < [startComponents weekday]) {
                NSInteger weekdayDelta = (7 - [startComponents weekday]) + requiredDayOfWeek;
                
                [resultComponents setDay:[resultComponents day] + weekdayDelta];
                
                startDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            }
            
            // If the required weekday is after the search weekday then advance to that weekday
            if (requiredDayOfWeek > [searchComponents weekday]) {
                NSInteger weekdayDelta = requiredDayOfWeek - [searchComponents weekday];
                
                [searchComponents setDay:[searchComponents day] + weekdayDelta];
                
                searchDate = [[NSDate gregorianCalendar] dateFromComponents:searchComponents];
            } // If the required weekday is before the search weekday then advance to that weekday wrapping into the next week
            else if (requiredDayOfWeek < [searchComponents weekday]) {
                NSInteger weekdayDelta = (7 - [searchComponents weekday]) + requiredDayOfWeek;
                
                [searchComponents setDay:[searchComponents day] + weekdayDelta];
                
                searchDate = [[NSDate gregorianCalendar] dateFromComponents:searchComponents];
            }
            
            // Calculate the delta in days between start and the search point
            NSInteger daysDelta = [[[NSDate gregorianCalendar] components:ICL_DayCalendarUnit
                                                        fromDate:startDate
                                                          toDate:searchDate
                                                         options:0] day];
            
            // Round to the nearest next week
            NSInteger roundedDaysDelta = startAndSearchSame ? 7 : (daysDelta + (daysDelta % 7));
            
            [resultComponents setDay:[resultComponents day] + roundedDaysDelta];
            
            NSDate* resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            return resultDate;
        }
            break;
            
        case estFortnightly: {
            NSInteger requiredDayOfWeek = edsoSunday;
            
            // if the schedule options are present and have a value then use that
            if (scheduleOptions && ([scheduleOptions count] > 0)) {
                requiredDayOfWeek = [[scheduleOptions firstObject] integerValue] + 1;
            } // otherwise determine the day of the week from the start date
            else {
                requiredDayOfWeek = [startComponents weekday];
            }
            
            BOOL startAndSearchSame = [startDate isEqualToDate:searchDate];
            
            // If the required weekday is after the starting weekday then advance to that weekday
            if (requiredDayOfWeek > [startComponents weekday]) {
                NSInteger weekdayDelta = requiredDayOfWeek - [startComponents weekday];
                
                [resultComponents setDay:[resultComponents day] + weekdayDelta];
                
                startDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            } // If the required weekday is before the starting weekday then advance to that weekday wrapping into the next week
            else if (requiredDayOfWeek < [startComponents weekday]) {
                NSInteger weekdayDelta = (7 - [startComponents weekday]) + requiredDayOfWeek;
                
                [resultComponents setDay:[resultComponents day] + weekdayDelta];
                
                startDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            }
            
            // If the required weekday is after the search weekday then advance to that weekday
            if (requiredDayOfWeek > [searchComponents weekday]) {
                NSInteger weekdayDelta = requiredDayOfWeek - [searchComponents weekday];
                
                [searchComponents setDay:[searchComponents day] + weekdayDelta];
                
                searchDate = [[NSDate gregorianCalendar] dateFromComponents:searchComponents];
            } // If the required weekday is before the search weekday then advance to that weekday wrapping into the next week
            else if (requiredDayOfWeek < [searchComponents weekday]) {
                NSInteger weekdayDelta = (7 - [searchComponents weekday]) + requiredDayOfWeek;
                
                [searchComponents setDay:[searchComponents day] + weekdayDelta];
                
                searchDate = [[NSDate gregorianCalendar] dateFromComponents:searchComponents];
            }
            
            // Calculate the delta in days between start and the search point
            NSInteger daysDelta = [[[NSDate gregorianCalendar] components:ICL_DayCalendarUnit
                                                        fromDate:startDate
                                                          toDate:searchDate
                                                         options:0] day];
            
            // Round to the nearest next week
            NSInteger roundedDaysDelta = startAndSearchSame ? 14 : (daysDelta + (daysDelta % 14));
            
            [resultComponents setDay:[resultComponents day] + roundedDaysDelta];
            
            NSDate* resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            return resultDate;
        }
            break;
            
        case estMonthly: {
            // Snap to the first date in the search month
            [resultComponents setDay:1];
            [resultComponents setMonth:[searchComponents month]];
            [resultComponents setYear:[searchComponents year]];
            NSDate* resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            // Snap the day to be in the valid range for that month
            NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:resultDate];
            [resultComponents setDay:MIN([startComponents day], dayRange.length)];
            resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            // If the resulting date is earlier than the search date then tick over to the next month
            if ([resultDate compare:searchDate] == NSOrderedAscending) {
                // increment over to the next year
                [resultComponents setDay:1];
                [resultComponents setMonth:[resultComponents month] + 1];
                resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
                
                // Snap the day to be in the valid range for that month
                NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:resultDate];
                [resultComponents setDay:MIN([startComponents day], dayRange.length)];
                
                // retrieve the final date
                resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            }
            
            return resultDate;
        }
            break;
            
        case estQuarterly: {
            // Calculate the number of months between the search point and the start point
            NSInteger monthDelta = ([searchComponents month] - [startComponents month]) +
            (([searchComponents year] - [startComponents year]) * 12);
            
            // Round up to the nearest quarter
            NSInteger roundedMonthDelta = monthDelta == 0 ? 3 : (monthDelta + (monthDelta % 3));
            
            // Move forward to the next quarter
            [resultComponents setDay:1];
            [resultComponents setMonth:[searchComponents month] + roundedMonthDelta];
            NSDate* resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            // Snap the day to be in the valid range for that month
            NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:resultDate];
            [resultComponents setDay:MIN([startComponents day], dayRange.length)];
            
            // retrieve the final date
            resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            return resultDate;
        }
            break;
            
        case estAnnually: {
            // Snap to the search year
            [resultComponents setDay:1];
            [resultComponents setYear:[searchComponents year]];
            NSDate* resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            // Snap the day to be in the valid range for that month
            NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:resultDate];
            [resultComponents setDay:MIN([startComponents day], dayRange.length)];
            resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            
            // If the resulting date is earlier than the search date then tick over to the next year
            if ([resultDate compare:searchDate] == NSOrderedAscending) {
                // increment over to the next year
                [resultComponents setDay:1];
                [resultComponents setYear:[resultComponents year] + 1];
                resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
                
                // Snap the day to be in the valid range for that month
                NSRange dayRange = [[NSDate gregorianCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:resultDate];
                [resultComponents setDay:MIN([startComponents day], dayRange.length)];
                
                // retrieve the final date
                resultDate = [[NSDate gregorianCalendar] dateFromComponents:resultComponents];
            }
            
            return resultDate;
        }
            break;
            
        default:
            break;
    }
    
    return nil;
}

@end
