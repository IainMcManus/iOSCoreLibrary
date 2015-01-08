//
//  ICLScheduleHelper_Tests.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 9/01/2015.
//  Copyright (c) 2015 Injaia. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <iOSCoreLibrary/ICLScheduleHelper.h>

@interface ICLScheduleHelper_Tests : XCTestCase

@end

@implementation ICLScheduleHelper_Tests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (BOOL) compareDateArrays:(NSArray*) lhs rhs:(NSArray*) rhs {
    if ([lhs count] != [rhs count]) {
        return NO;
    }
    
    for (NSUInteger index = 0; index < [lhs count]; ++index) {
        if (![lhs[index] isEqualToDate:rhs[index]]) {
            return NO;
        }
    }
    
    return YES;
}

- (NSDate*) randomDate:(NSDate*) startDate {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:startDate];
    
    [dateComponents setDay:[dateComponents day] + arc4random_uniform(365 * 2)];
    
    return [calendar dateFromComponents:dateComponents];
}

- (NSDate*) buildDate:(NSArray*) dayMonthYear {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    
    [dateComponents setDay:[dayMonthYear[0] integerValue]];
    [dateComponents setMonth:[dayMonthYear[1] integerValue]];
    [dateComponents setYear:[dayMonthYear[2] integerValue]];
    
    return [calendar dateFromComponents:dateComponents];
}

- (void) testNoSchedule {
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate* firstDate = [self randomDate:[NSDate date]];
    
    NSDateComponents* dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:firstDate];
    
    // Second date is a small amount (1-2 months) ahead of the baseline
    [dateComponents setDay:(arc4random_uniform(60) + 1)];
    NSDate* secondDate = [calendar dateFromComponents:dateComponents];
    
    // Third date is at least a year ahead
    [dateComponents setDay:365 * (arc4random_uniform(5) + 1)];
    NSDate* thirdDate = [calendar dateFromComponents:dateComponents];
    
    // Fourth date is a small amount ahead of the third date
    [dateComponents setDay:(arc4random_uniform(60) + 1)];
    NSDate* fourthDate = [calendar dateFromComponents:dateComponents];
    
    NSDictionary* repeatConfig = @{kICLSchedule_Type: @(estNever),
                                   kICLSchedule_StartDate: firstDate,
                                   kICLSchedule_EndDate: fourthDate,
                                   kICLSchedule_Options: @[]};
    
    NSArray* dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                                     fromDate:secondDate
                                                       toDate:thirdDate];
    
    XCTAssertTrue([dates count] == 0, @"Never should not generate any scheduled dates");
}

- (void) testDailySchedule {
    ScheduleType scheduleType = estDaily;
    DailyScheduleOptions selectedDay = edsoTuesday;
    
    NSDate* firstDate = [self buildDate:@[@(23), @(1), @(2012)]];
    NSDate* secondDate = [self buildDate:@[@(30), @(1), @(2012)]];
    NSDate* thirdDate = [self buildDate:@[@(8), @(5), @(2012)]];
    NSDate* fourthDate = [self buildDate:@[@(24), @(5), @(2012)]];
    
    NSDictionary* repeatConfig = nil;
    NSArray* dates = nil;
    NSArray* expectedDates = nil;
    
    // Test Case 1 - Start Date < From Date  < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 2 - From Date  < Start Date < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 3 - Start Date < From Date  < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 4 - From Date  < Start Date < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 5 - Start Date < From Date  < toDate  < null
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 6 - Start Date < From Date  < toDate  < null
    //  - Covering wrapping for leap year
    firstDate = [self buildDate:@[@(3), @(2), @(2012)]];
    secondDate = [self buildDate:@[@(4), @(2), @(2012)]];
    thirdDate = [self buildDate:@[@(27), @(4), @(2012)]];
    fourthDate = [self buildDate:@[@(26), @(4), @(2012)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[@(edsoWednesday)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(8), @(2), @(2012)]],
                      [self buildDate:@[@(15), @(2), @(2012)]],
                      [self buildDate:@[@(22), @(2), @(2012)]],
                      [self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(7), @(3), @(2012)]],
                      [self buildDate:@[@(14), @(3), @(2012)]],
                      [self buildDate:@[@(21), @(3), @(2012)]],
                      [self buildDate:@[@(28), @(3), @(2012)]],
                      [self buildDate:@[@(4), @(4), @(2012)]],
                      [self buildDate:@[@(11), @(4), @(2012)]],
                      [self buildDate:@[@(18), @(4), @(2012)]],
                      [self buildDate:@[@(25), @(4), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 7 - Start Date < From Date  < toDate  < endDate
    // Where start date is after the repeat day
    
    firstDate = [self buildDate:@[@(26), @(1), @(2012)]];
    secondDate = [self buildDate:@[@(30), @(1), @(2012)]];
    thirdDate = [self buildDate:@[@(8), @(5), @(2012)]];
    fourthDate = [self buildDate:@[@(24), @(5), @(2012)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(edsoTuesday)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 8 - Start Date < From Date  < toDate  < endDate
    // Where start date is after the repeat day
    
    firstDate = [self buildDate:@[@(24), @(1), @(2012)]];
    secondDate = [self buildDate:@[@(30), @(1), @(2012)]];
    thirdDate = [self buildDate:@[@(3), @(3), @(2012)]];
    fourthDate = [self buildDate:@[@(4), @(3), @(2012)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(edsoMonday), @(edsoWednesday), @(edsoFriday)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(30), @(1), @(2012)]],
                      [self buildDate:@[@(1), @(2), @(2012)]],
                      [self buildDate:@[@(3), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(2), @(2012)]],
                      [self buildDate:@[@(8), @(2), @(2012)]],
                      [self buildDate:@[@(10), @(2), @(2012)]],
                      [self buildDate:@[@(13), @(2), @(2012)]],
                      [self buildDate:@[@(15), @(2), @(2012)]],
                      [self buildDate:@[@(17), @(2), @(2012)]],
                      [self buildDate:@[@(20), @(2), @(2012)]],
                      [self buildDate:@[@(22), @(2), @(2012)]],
                      [self buildDate:@[@(24), @(2), @(2012)]],
                      [self buildDate:@[@(27), @(2), @(2012)]],
                      [self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(2), @(3), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
}

- (void) testWeeklySchedule {
    ScheduleType scheduleType = estWeekly;
    DailyScheduleOptions selectedDay = edsoTuesday;
    
    NSDate* firstDate = [self buildDate:@[@(23), @(1), @(2012)]];
    NSDate* secondDate = [self buildDate:@[@(30), @(1), @(2012)]];
    NSDate* thirdDate = [self buildDate:@[@(8), @(5), @(2012)]];
    NSDate* fourthDate = [self buildDate:@[@(24), @(5), @(2012)]];
    
    NSDictionary* repeatConfig = nil;
    NSArray* dates = nil;
    NSArray* expectedDates = nil;
    
    // Test Case 1 - Start Date < From Date  < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 2 - From Date  < Start Date < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 3 - Start Date < From Date  < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 4 - From Date  < Start Date < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 5 - Start Date < From Date  < toDate  < null
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2012)]],
                      [self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 6 - Start Date < From Date  < toDate  < null
    //  - Covering wrapping for leap year
    firstDate = [self buildDate:@[@(3), @(2), @(2012)]];
    secondDate = [self buildDate:@[@(4), @(2), @(2012)]];
    thirdDate = [self buildDate:@[@(27), @(4), @(2012)]];
    fourthDate = [self buildDate:@[@(26), @(4), @(2012)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[@(edsoWednesday)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(8), @(2), @(2012)]],
                      [self buildDate:@[@(15), @(2), @(2012)]],
                      [self buildDate:@[@(22), @(2), @(2012)]],
                      [self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(7), @(3), @(2012)]],
                      [self buildDate:@[@(14), @(3), @(2012)]],
                      [self buildDate:@[@(21), @(3), @(2012)]],
                      [self buildDate:@[@(28), @(3), @(2012)]],
                      [self buildDate:@[@(4), @(4), @(2012)]],
                      [self buildDate:@[@(11), @(4), @(2012)]],
                      [self buildDate:@[@(18), @(4), @(2012)]],
                      [self buildDate:@[@(25), @(4), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
}

- (void) testFortnightlySchedule {
    ScheduleType scheduleType = estFortnightly;
    DailyScheduleOptions selectedDay = edsoTuesday;
    
    NSDate* firstDate = [self buildDate:@[@(23), @(1), @(2012)]];
    NSDate* secondDate = [self buildDate:@[@(30), @(1), @(2012)]];
    NSDate* thirdDate = [self buildDate:@[@(8), @(5), @(2012)]];
    NSDate* fourthDate = [self buildDate:@[@(24), @(5), @(2012)]];
    
    NSDictionary* repeatConfig = nil;
    NSArray* dates = nil;
    NSArray* expectedDates = nil;
    
    // Test Case 1 - Start Date < From Date  < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 2 - From Date  < Start Date < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 3 - Start Date < From Date  < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 4 - From Date  < Start Date < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(14), @(2), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2012)]],
                      [self buildDate:@[@(13), @(3), @(2012)]],
                      [self buildDate:@[@(27), @(3), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(24), @(4), @(2012)]],
                      [self buildDate:@[@(8), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 5 - Start Date < From Date  < toDate  < null
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[@(selectedDay)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(7), @(2), @(2012)]],
                      [self buildDate:@[@(21), @(2), @(2012)]],
                      [self buildDate:@[@(6), @(3), @(2012)]],
                      [self buildDate:@[@(20), @(3), @(2012)]],
                      [self buildDate:@[@(3), @(4), @(2012)]],
                      [self buildDate:@[@(17), @(4), @(2012)]],
                      [self buildDate:@[@(1), @(5), @(2012)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 6 - Start Date < From Date  < toDate  < null
    //  - Covering wrapping for leap year
    firstDate = [self buildDate:@[@(10), @(2), @(2012)]];
    secondDate = [self buildDate:@[@(11), @(2), @(2012)]];
    thirdDate = [self buildDate:@[@(27), @(4), @(2012)]];
    fourthDate = [self buildDate:@[@(26), @(4), @(2012)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[@(edsoWednesday)]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(15), @(2), @(2012)]],
                      [self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(14), @(3), @(2012)]],
                      [self buildDate:@[@(28), @(3), @(2012)]],
                      [self buildDate:@[@(11), @(4), @(2012)]],
                      [self buildDate:@[@(25), @(4), @(2012)]]];
    
    // Test Case 7 - Start Date < From Date  < toDate  < null
    //  - Covering wrapping for leap year
    firstDate = [self buildDate:@[@(31), @(7), @(2014)]];
    secondDate = [self buildDate:@[@(4), @(8), @(2014)]];
    thirdDate = [self buildDate:@[@(23), @(9), @(2014)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(14), @(8), @(2014)]],
                      [self buildDate:@[@(28), @(8), @(2014)]],
                      [self buildDate:@[@(11), @(9), @(2014)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
}

- (void) testMonthlySchedule {
    ScheduleType scheduleType = estMonthly;
    
    NSDate* firstDate = [self buildDate:@[@(31), @(1), @(2012)]];
    NSDate* secondDate = [self buildDate:@[@(10), @(2), @(2012)]];
    NSDate* thirdDate = [self buildDate:@[@(8), @(3), @(2013)]];
    NSDate* fourthDate = [self buildDate:@[@(24), @(3), @(2013)]];
    
    NSDictionary* repeatConfig = nil;
    NSArray* dates = nil;
    NSArray* expectedDates = nil;
    
    // Test Case 1 - Start Date < From Date  < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(31), @(3), @(2012)]],
                      [self buildDate:@[@(30), @(4), @(2012)]],
                      [self buildDate:@[@(31), @(5), @(2012)]],
                      [self buildDate:@[@(30), @(6), @(2012)]],
                      [self buildDate:@[@(31), @(7), @(2012)]],
                      [self buildDate:@[@(31), @(8), @(2012)]],
                      [self buildDate:@[@(30), @(9), @(2012)]],
                      [self buildDate:@[@(31), @(10), @(2012)]],
                      [self buildDate:@[@(30), @(11), @(2012)]],
                      [self buildDate:@[@(31), @(12), @(2012)]],
                      [self buildDate:@[@(31), @(1), @(2013)]],
                      [self buildDate:@[@(28), @(2), @(2013)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 2 - From Date  < Start Date < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(10), @(2), @(2012)]],
                      [self buildDate:@[@(10), @(3), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(5), @(2012)]],
                      [self buildDate:@[@(10), @(6), @(2012)]],
                      [self buildDate:@[@(10), @(7), @(2012)]],
                      [self buildDate:@[@(10), @(8), @(2012)]],
                      [self buildDate:@[@(10), @(9), @(2012)]],
                      [self buildDate:@[@(10), @(10), @(2012)]],
                      [self buildDate:@[@(10), @(11), @(2012)]],
                      [self buildDate:@[@(10), @(12), @(2012)]],
                      [self buildDate:@[@(10), @(1), @(2013)]],
                      [self buildDate:@[@(10), @(2), @(2013)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 3 - Start Date < From Date  < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(31), @(3), @(2012)]],
                      [self buildDate:@[@(30), @(4), @(2012)]],
                      [self buildDate:@[@(31), @(5), @(2012)]],
                      [self buildDate:@[@(30), @(6), @(2012)]],
                      [self buildDate:@[@(31), @(7), @(2012)]],
                      [self buildDate:@[@(31), @(8), @(2012)]],
                      [self buildDate:@[@(30), @(9), @(2012)]],
                      [self buildDate:@[@(31), @(10), @(2012)]],
                      [self buildDate:@[@(30), @(11), @(2012)]],
                      [self buildDate:@[@(31), @(12), @(2012)]],
                      [self buildDate:@[@(31), @(1), @(2013)]],
                      [self buildDate:@[@(28), @(2), @(2013)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 4 - From Date  < Start Date < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(10), @(2), @(2012)]],
                      [self buildDate:@[@(10), @(3), @(2012)]],
                      [self buildDate:@[@(10), @(4), @(2012)]],
                      [self buildDate:@[@(10), @(5), @(2012)]],
                      [self buildDate:@[@(10), @(6), @(2012)]],
                      [self buildDate:@[@(10), @(7), @(2012)]],
                      [self buildDate:@[@(10), @(8), @(2012)]],
                      [self buildDate:@[@(10), @(9), @(2012)]],
                      [self buildDate:@[@(10), @(10), @(2012)]],
                      [self buildDate:@[@(10), @(11), @(2012)]],
                      [self buildDate:@[@(10), @(12), @(2012)]],
                      [self buildDate:@[@(10), @(1), @(2013)]],
                      [self buildDate:@[@(10), @(2), @(2013)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 5 - Start Date < From Date  < toDate  < null
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(29), @(2), @(2012)]],
                      [self buildDate:@[@(31), @(3), @(2012)]],
                      [self buildDate:@[@(30), @(4), @(2012)]],
                      [self buildDate:@[@(31), @(5), @(2012)]],
                      [self buildDate:@[@(30), @(6), @(2012)]],
                      [self buildDate:@[@(31), @(7), @(2012)]],
                      [self buildDate:@[@(31), @(8), @(2012)]],
                      [self buildDate:@[@(30), @(9), @(2012)]],
                      [self buildDate:@[@(31), @(10), @(2012)]],
                      [self buildDate:@[@(30), @(11), @(2012)]],
                      [self buildDate:@[@(31), @(12), @(2012)]],
                      [self buildDate:@[@(31), @(1), @(2013)]],
                      [self buildDate:@[@(28), @(2), @(2013)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
}

- (void) testQuarterlySchedule {
    ScheduleType scheduleType = estQuarterly;
    
    NSDate* firstDate = [self buildDate:@[@(31), @(10), @(2012)]];
    NSDate* secondDate = [self buildDate:@[@(4), @(11), @(2012)]];
    NSDate* thirdDate = [self buildDate:@[@(8), @(11), @(2014)]];
    NSDate* fourthDate = [self buildDate:@[@(24), @(11), @(2014)]];
    
    NSDictionary* repeatConfig = nil;
    NSArray* dates = nil;
    NSArray* expectedDates = nil;
    
    // Test Case 1 - Start Date < From Date  < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2013)]],
                      [self buildDate:@[@(30), @(4), @(2013)]],
                      [self buildDate:@[@(31), @(7), @(2013)]],
                      [self buildDate:@[@(31), @(10), @(2013)]],
                      [self buildDate:@[@(31), @(1), @(2014)]],
                      [self buildDate:@[@(30), @(4), @(2014)]],
                      [self buildDate:@[@(31), @(7), @(2014)]],
                      [self buildDate:@[@(31), @(10), @(2014)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 2 - From Date  < Start Date < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(4), @(2), @(2013)]],
                      [self buildDate:@[@(4), @(5), @(2013)]],
                      [self buildDate:@[@(4), @(8), @(2013)]],
                      [self buildDate:@[@(4), @(11), @(2013)]],
                      [self buildDate:@[@(4), @(2), @(2014)]],
                      [self buildDate:@[@(4), @(5), @(2014)]],
                      [self buildDate:@[@(4), @(8), @(2014)]],
                      [self buildDate:@[@(4), @(11), @(2014)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 3 - Start Date < From Date  < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2013)]],
                      [self buildDate:@[@(30), @(4), @(2013)]],
                      [self buildDate:@[@(31), @(7), @(2013)]],
                      [self buildDate:@[@(31), @(10), @(2013)]],
                      [self buildDate:@[@(31), @(1), @(2014)]],
                      [self buildDate:@[@(30), @(4), @(2014)]],
                      [self buildDate:@[@(31), @(7), @(2014)]],
                      [self buildDate:@[@(31), @(10), @(2014)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 4 - From Date  < Start Date < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(4), @(2), @(2013)]],
                      [self buildDate:@[@(4), @(5), @(2013)]],
                      [self buildDate:@[@(4), @(8), @(2013)]],
                      [self buildDate:@[@(4), @(11), @(2013)]],
                      [self buildDate:@[@(4), @(2), @(2014)]],
                      [self buildDate:@[@(4), @(5), @(2014)]],
                      [self buildDate:@[@(4), @(8), @(2014)]],
                      [self buildDate:@[@(4), @(11), @(2014)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 5 - Start Date < From Date  < toDate  < null
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(31), @(1), @(2013)]],
                      [self buildDate:@[@(30), @(4), @(2013)]],
                      [self buildDate:@[@(31), @(7), @(2013)]],
                      [self buildDate:@[@(31), @(10), @(2013)]],
                      [self buildDate:@[@(31), @(1), @(2014)]],
                      [self buildDate:@[@(30), @(4), @(2014)]],
                      [self buildDate:@[@(31), @(7), @(2014)]],
                      [self buildDate:@[@(31), @(10), @(2014)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 6 - Start Date < From Date  < toDate  < endDate
    //  - From Date = 29th April
    
    firstDate = [self buildDate:@[@(29), @(2), @(2012)]];
    secondDate = [self buildDate:@[@(24), @(3), @(2012)]];
    thirdDate = [self buildDate:@[@(4), @(12), @(2016)]];
    fourthDate = [self buildDate:@[@(24), @(12), @(2016)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(29), @(5), @(2012)]],
                      [self buildDate:@[@(29), @(8), @(2012)]],
                      [self buildDate:@[@(29), @(11), @(2012)]],
                      [self buildDate:@[@(28), @(2), @(2013)]],
                      [self buildDate:@[@(29), @(5), @(2013)]],
                      [self buildDate:@[@(29), @(8), @(2013)]],
                      [self buildDate:@[@(29), @(11), @(2013)]],
                      [self buildDate:@[@(28), @(2), @(2014)]],
                      [self buildDate:@[@(29), @(5), @(2014)]],
                      [self buildDate:@[@(29), @(8), @(2014)]],
                      [self buildDate:@[@(29), @(11), @(2014)]],
                      [self buildDate:@[@(28), @(2), @(2015)]],
                      [self buildDate:@[@(29), @(5), @(2015)]],
                      [self buildDate:@[@(29), @(8), @(2015)]],
                      [self buildDate:@[@(29), @(11), @(2015)]],
                      [self buildDate:@[@(29), @(2), @(2016)]],
                      [self buildDate:@[@(29), @(5), @(2016)]],
                      [self buildDate:@[@(29), @(8), @(2016)]],
                      [self buildDate:@[@(29), @(11), @(2016)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
}

- (void) testAnnuallySchedule {
    ScheduleType scheduleType = estAnnually;
    
    NSDate* firstDate = [self buildDate:@[@(14), @(10), @(2012)]];
    NSDate* secondDate = [self buildDate:@[@(24), @(10), @(2012)]];
    NSDate* thirdDate = [self buildDate:@[@(4), @(8), @(2022)]];
    NSDate* fourthDate = [self buildDate:@[@(24), @(8), @(2022)]];
    
    NSDictionary* repeatConfig = nil;
    NSArray* dates = nil;
    NSArray* expectedDates = nil;
    
    // Test Case 1 - Start Date < From Date  < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(14), @(10), @(2013)]],
                      [self buildDate:@[@(14), @(10), @(2014)]],
                      [self buildDate:@[@(14), @(10), @(2015)]],
                      [self buildDate:@[@(14), @(10), @(2016)]],
                      [self buildDate:@[@(14), @(10), @(2017)]],
                      [self buildDate:@[@(14), @(10), @(2018)]],
                      [self buildDate:@[@(14), @(10), @(2019)]],
                      [self buildDate:@[@(14), @(10), @(2020)]],
                      [self buildDate:@[@(14), @(10), @(2021)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 2 - From Date  < Start Date < toDate  < endDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: fourthDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(24), @(10), @(2012)]],
                      [self buildDate:@[@(24), @(10), @(2013)]],
                      [self buildDate:@[@(24), @(10), @(2014)]],
                      [self buildDate:@[@(24), @(10), @(2015)]],
                      [self buildDate:@[@(24), @(10), @(2016)]],
                      [self buildDate:@[@(24), @(10), @(2017)]],
                      [self buildDate:@[@(24), @(10), @(2018)]],
                      [self buildDate:@[@(24), @(10), @(2019)]],
                      [self buildDate:@[@(24), @(10), @(2020)]],
                      [self buildDate:@[@(24), @(10), @(2021)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 3 - Start Date < From Date  < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(14), @(10), @(2013)]],
                      [self buildDate:@[@(14), @(10), @(2014)]],
                      [self buildDate:@[@(14), @(10), @(2015)]],
                      [self buildDate:@[@(14), @(10), @(2016)]],
                      [self buildDate:@[@(14), @(10), @(2017)]],
                      [self buildDate:@[@(14), @(10), @(2018)]],
                      [self buildDate:@[@(14), @(10), @(2019)]],
                      [self buildDate:@[@(14), @(10), @(2020)]],
                      [self buildDate:@[@(14), @(10), @(2021)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 4 - From Date  < Start Date < endDate < toDate
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: secondDate,
                     kICLSchedule_EndDate: thirdDate,
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:firstDate
                                              toDate:fourthDate];
    
    expectedDates = @[[self buildDate:@[@(24), @(10), @(2012)]],
                      [self buildDate:@[@(24), @(10), @(2013)]],
                      [self buildDate:@[@(24), @(10), @(2014)]],
                      [self buildDate:@[@(24), @(10), @(2015)]],
                      [self buildDate:@[@(24), @(10), @(2016)]],
                      [self buildDate:@[@(24), @(10), @(2017)]],
                      [self buildDate:@[@(24), @(10), @(2018)]],
                      [self buildDate:@[@(24), @(10), @(2019)]],
                      [self buildDate:@[@(24), @(10), @(2020)]],
                      [self buildDate:@[@(24), @(10), @(2021)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 5 - Start Date < From Date  < toDate  < null
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(14), @(10), @(2013)]],
                      [self buildDate:@[@(14), @(10), @(2014)]],
                      [self buildDate:@[@(14), @(10), @(2015)]],
                      [self buildDate:@[@(14), @(10), @(2016)]],
                      [self buildDate:@[@(14), @(10), @(2017)]],
                      [self buildDate:@[@(14), @(10), @(2018)]],
                      [self buildDate:@[@(14), @(10), @(2019)]],
                      [self buildDate:@[@(14), @(10), @(2020)]],
                      [self buildDate:@[@(14), @(10), @(2021)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
    
    // Test Case 6 - Start Date < From Date  < toDate  < endDate
    //  - From Date = 29th April
    
    firstDate = [self buildDate:@[@(29), @(2), @(2012)]];
    secondDate = [self buildDate:@[@(24), @(3), @(2012)]];
    thirdDate = [self buildDate:@[@(4), @(8), @(2022)]];
    fourthDate = [self buildDate:@[@(24), @(8), @(2022)]];
    
    repeatConfig = @{kICLSchedule_Type: @(scheduleType),
                     kICLSchedule_StartDate: firstDate,
                     kICLSchedule_EndDate: [NSNull null],
                     kICLSchedule_Options: @[]};
    
    dates = [ICLScheduleHelper generateScheduleDates:repeatConfig
                                            fromDate:secondDate
                                              toDate:thirdDate];
    
    expectedDates = @[[self buildDate:@[@(28), @(2), @(2013)]],
                      [self buildDate:@[@(28), @(2), @(2014)]],
                      [self buildDate:@[@(28), @(2), @(2015)]],
                      [self buildDate:@[@(29), @(2), @(2016)]],
                      [self buildDate:@[@(28), @(2), @(2017)]],
                      [self buildDate:@[@(28), @(2), @(2018)]],
                      [self buildDate:@[@(28), @(2), @(2019)]],
                      [self buildDate:@[@(29), @(2), @(2020)]],
                      [self buildDate:@[@(28), @(2), @(2021)]],
                      [self buildDate:@[@(28), @(2), @(2022)]]];
    
    XCTAssertTrue([self compareDateArrays:dates rhs:expectedDates], @"Calculated dates do not match");
}

@end
