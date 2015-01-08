//
//  ICLScheduleHelper.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 31/07/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    estNever,
    
    estDaily,
    estWeekly,
    estFortnightly,
    estMonthly,
    estQuarterly,
    estAnnually,
    
    estNumTypes
} ScheduleType;

typedef enum {
    edsoSunday,
    edsoMonday,
    edsoTuesday,
    edsoWednesday,
    edsoThursday,
    edsoFriday,
    edsoSaturday
} DailyScheduleOptions;

extern NSString* const kICLSchedule_StartDate;
extern NSString* const kICLSchedule_EndDate;
extern NSString* const kICLSchedule_Options;
extern NSString* const kICLSchedule_Type;

@interface ICLScheduleHelper : NSObject

+ (NSArray*) generateScheduleDates:(NSDictionary*) repeatConfig
                          fromDate:(NSDate*) fromDate
                            toDate:(NSDate*) toDate;

@end
