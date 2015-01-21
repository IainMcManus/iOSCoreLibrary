//
//  ICLFilterableViewController.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 20/07/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    eftAll,
    eftWeek,
    eftMonth,
    eftCustom,
    
    eftNumFilterTypes
} FilterType;

@interface ICLFilterableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIToolbar *filterToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filter_previousButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filter_currentButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filter_nextButton;

- (IBAction)filter_previous:(id)sender;
- (IBAction)filter_current:(id)sender;
- (IBAction)filter_next:(id)sender;

- (FilterType) filterType;
- (NSDate*) filterStartDate;
- (NSDate*) filterEndDate;

- (BOOL) hasFilterableData;

- (NSDate*) earliestPossibleDate;
- (NSDate*) latestPossibleDate;

- (void) resetFilterDates;
- (void) ensureDateValidity;

- (void) updateFilterData;
- (void) updateFilterDisplay;

- (NSString*) getNoDataMessage;
- (NSDate*) getFilterDefault_StartDate;
- (NSDate*) getFilterDefault_EndDate;
- (FilterType) getFilterDefault_Type;
- (NSArray*) getFilterDefault_AvailableTypes;

- (BOOL) canMove_Next;
- (BOOL) canMove_Previous;

- (void) copyFilterStateFrom:(ICLFilterableViewController*) otherController;

@end
