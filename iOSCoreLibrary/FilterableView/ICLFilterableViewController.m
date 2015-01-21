//
//  ICLFilterableViewController.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 20/07/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLFilterableViewController.h"

#import "NSDate+Extensions.h"
#import "ICLDatePickerPopupViewController.h"
#import "NSBundle+InternalExtensions.h"

@interface ICLFilterableViewController () <UIActionSheetDelegate, ICLDatePickerPopupViewControllerDelegate>

@end

@implementation ICLFilterableViewController {
    FilterType _filterType;
    NSDate* _filterStartDate;
    NSDate* _filterEndDate;
    NSDateFormatter* _filterDateFormatter;
    
    UIActionSheet* _filterTypeSheet;
    
    NSString* _filter_All;
    NSString* _filter_Week;
    NSString* _filter_Month;
    NSString* _filter_Custom;
    NSString* _filter_GoToDate;
    NSString* _cancel;
    
    NSArray* _filterTypeText;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _filter_All = NSLocalizedStringFromTableInBundle(@"FilterType.All", @"Filters", [NSBundle localisationBundle], @"Show all");
    _filter_Week = NSLocalizedStringFromTableInBundle(@"FilterType.Week", @"Filters", [NSBundle localisationBundle], @"Filter by week");
    _filter_Month = NSLocalizedStringFromTableInBundle(@"FilterType.Month", @"Filters", [NSBundle localisationBundle], @"Filter by month");
    _filter_Custom = NSLocalizedStringFromTableInBundle(@"FilterType.Custom", @"Filters", [NSBundle localisationBundle], @"Custom range");
    _filter_GoToDate = NSLocalizedStringFromTableInBundle(@"FilterType.GoToDate", @"Filters", [NSBundle localisationBundle], @"Go to date");
    
    _cancel = NSLocalizedStringFromTableInBundle(@"Cancel", @"Common", [NSBundle localisationBundle], @"Cancel");
    
    _filterTypeText = @[_filter_All,
                        _filter_Week,
                        _filter_Month,
                        _filter_Custom];
    
    _filterDateFormatter = [[NSDateFormatter alloc] init];
    [_filterDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    if (Using_iPad) {
        [_filterDateFormatter setDateStyle:NSDateFormatterLongStyle];
    }
    else {
        [_filterDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }
    
    [self resetFilterDates];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (FilterType) filterType {
    return _filterType;
}

- (NSDate*) filterStartDate {
    return _filterStartDate;
}

- (NSDate*) filterEndDate {
    return _filterEndDate;
}

- (BOOL) hasFilterableData {
    assert(0);
    return NO;
}

- (NSDate*) earliestPossibleDate {
    assert(0);
    return nil;
}

- (NSDate*) latestPossibleDate {
    assert(0);
    return nil;
}

- (void) updateFilterData {
    assert(0);
}

- (NSString*) getNoDataMessage {
    return NSLocalizedStringFromTableInBundle(@"Filter.Generic.NoData", @"Filters", [NSBundle localisationBundle], @"No data present");
}

- (NSDate*) getFilterDefault_StartDate {
    return nil;
}

- (NSDate*) getFilterDefault_EndDate {
    return nil;
}

- (FilterType) getFilterDefault_Type {
    return eftAll;
}

- (NSArray*) getFilterDefault_AvailableTypes {
    return @[@(eftAll), @(eftWeek), @(eftMonth), @(eftCustom)];
}

- (BOOL) canMove_Next {
    return YES;
}

- (BOOL) canMove_Previous {
    return YES;
}

- (void) resetFilterDates {
    _filterStartDate = [self getFilterDefault_StartDate];
    _filterEndDate = [self getFilterDefault_EndDate];
    _filterType = [self getFilterDefault_Type];
}

- (void) ensureDateValidity {
    NSDate* earliestPossibleDate = [self earliestPossibleDate];
    NSDate* latestPossibleDate = [self latestPossibleDate];
    
    // if the date order is wrong swap it
    if (_filterStartDate && _filterEndDate && ([_filterEndDate compare:_filterStartDate] == NSOrderedAscending)) {
        NSDate* temporary = _filterStartDate;
        _filterStartDate = _filterEndDate;
        _filterEndDate = temporary;
    }
    
    // if dates are missing for the all type then default to the entire range
    if (_filterType == eftAll) {
        if (!_filterStartDate) {
            _filterStartDate = [earliestPossibleDate copy];
        }
        if (!_filterEndDate) {
            _filterEndDate = [latestPossibleDate copy];
        }
    } // if dates are missing for the week type then try to use existing data, otherwise use current date as a basis
    else if (_filterType == eftWeek) {
        if (!_filterStartDate && !_filterEndDate) {
            _filterStartDate = [[NSDate date] startOfWeek];
            _filterEndDate = [[NSDate date] endOfWeek];
        }
        else if (!_filterStartDate && _filterEndDate) {
            _filterStartDate = [_filterEndDate startOfWeek];
            _filterEndDate = [_filterEndDate endOfWeek];
        }
        else if (_filterStartDate && !_filterEndDate){
            _filterStartDate = [_filterStartDate startOfWeek];
            _filterEndDate = [_filterStartDate endOfWeek];
        }
        else {
            _filterStartDate = [_filterStartDate startOfWeek];
            _filterEndDate = [_filterStartDate endOfWeek];
        }
    } // if dates are missing for the month type then try to use existing data, otherwise use current date as a basis
    else if (_filterType == eftMonth) {
        if (!_filterStartDate && !_filterEndDate) {
            _filterStartDate = [[NSDate date] startOfMonth];
            _filterEndDate = [[NSDate date] endOfMonth];
        }
        else if (!_filterStartDate && _filterEndDate) {
            _filterStartDate = [_filterEndDate startOfMonth];
            _filterEndDate = [_filterEndDate endOfMonth];
        }
        else if (_filterStartDate && !_filterEndDate){
            _filterStartDate = [_filterStartDate startOfMonth];
            _filterEndDate = [_filterStartDate endOfMonth];
        }
        else {
            _filterStartDate = [_filterStartDate startOfMonth];
            _filterEndDate = [_filterStartDate endOfMonth];
        }
    } // if dates are missing for the custom type then default to the entire range
    else if (_filterType == eftCustom) {
        if (!_filterStartDate) {
            _filterStartDate = [earliestPossibleDate copy];
        }
        if (!_filterEndDate) {
            _filterEndDate = [latestPossibleDate copy];
        }
    }
}

- (void) updateFilterDisplay {
    [self ensureDateValidity];
    
    if ([self hasFilterableData]) {
        NSString* startDateString = [_filterDateFormatter stringFromDate:_filterStartDate];
        NSString* endDateString = [_filterDateFormatter stringFromDate:_filterEndDate];
        
        [self.filter_currentButton setTitle:[NSString stringWithFormat:@"%@ - %@", startDateString, endDateString]];
        
        [self.filter_currentButton setEnabled:YES];

        BOOL allowPreviousAndNext = (_filterType != eftAll) && (_filterType != eftCustom);
        [self.filter_previousButton setEnabled:allowPreviousAndNext && [self canMove_Previous]];
        [self.filter_nextButton setEnabled:allowPreviousAndNext && [self canMove_Next]];
    }
    else {
        [self.filter_currentButton setTitle:[self getNoDataMessage]];
        
        [self.filter_previousButton setEnabled:NO];
        [self.filter_currentButton setEnabled:NO];
        [self.filter_nextButton setEnabled:NO];
    }
}

- (IBAction)filter_previous:(id)sender {
    if ([self hasFilterableData]) {
        if (_filterType == eftWeek) {
            _filterStartDate = [_filterStartDate previousWeek];
            _filterEndDate = [_filterStartDate endOfWeek];
            
            [self updateFilterData];
            [self updateFilterDisplay];
        }
        else if (_filterType == eftMonth) {
            _filterStartDate = [[_filterStartDate previousMonth] startOfMonth];
            _filterEndDate = [_filterStartDate endOfMonth];
            
            [self updateFilterData];
            [self updateFilterDisplay];
        }
    }
}

- (IBAction)filter_current:(id)sender {
    if ([self hasFilterableData]) {
        NSArray* supportedTypes = [self getFilterDefault_AvailableTypes];
        
        if ([supportedTypes count] > 1) {
            _filterTypeSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            
            // Add all of the supported filter types
            for (NSNumber* supportedType in supportedTypes) {
                [_filterTypeSheet addButtonWithTitle:_filterTypeText[[supportedType integerValue]]];
            }
            
            // Add the goto date option if not showing all
            if ((_filterType != eftAll) && (_filterType != eftCustom)) {
                [_filterTypeSheet addButtonWithTitle:_filter_GoToDate];
            }
            
            [_filterTypeSheet addButtonWithTitle:_cancel];
            [_filterTypeSheet setCancelButtonIndex:[_filterTypeSheet numberOfButtons] - 1];
            
            [_filterTypeSheet setDelegate:self];
            [_filterTypeSheet showFromBarButtonItem:self.filter_currentButton animated:YES];
        }
    }
}

- (IBAction)filter_next:(id)sender {
    if ([self hasFilterableData]) {
        if (_filterType == eftWeek) {
            _filterStartDate = [_filterStartDate nextWeek];
            _filterEndDate = [_filterStartDate endOfWeek];
            
            [self updateFilterData];
            [self updateFilterDisplay];
        }
        else if (_filterType == eftMonth) {
            _filterStartDate = [[_filterStartDate nextMonth] startOfMonth];
            _filterEndDate = [_filterStartDate endOfMonth];
            
            [self updateFilterData];
            [self updateFilterDisplay];
        }
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((actionSheet == _filterTypeSheet) && (buttonIndex != actionSheet.cancelButtonIndex)) {
            FilterType requestedType = eftNumFilterTypes;
            
            NSArray* supportedTypes = [self getFilterDefault_AvailableTypes];
            if (buttonIndex < [supportedTypes count]) {
                requestedType = (FilterType)[supportedTypes[buttonIndex] integerValue];
            }
            
            FilterType newFilterType = eftNumFilterTypes;
            
            if (requestedType == eftAll) {
                newFilterType = eftAll;
            }
            else if (requestedType == eftWeek) {
                newFilterType = eftWeek;
            }
            else if (requestedType == eftMonth) {
                newFilterType = eftMonth;
            }
            else if (requestedType == eftCustom) {
                ICLDatePickerPopupViewController* datePickerPopup = [ICLDatePickerPopupViewController create:self.filter_currentButton type:dpptStartAndEndDate];
                datePickerPopup.delegate = self;
                datePickerPopup.startDate = [_filterStartDate copy];
                datePickerPopup.endDate = [_filterEndDate copy];
                
                [datePickerPopup show];
                
                return;
            } // otherwise is goto date
            else {
                if (_filterType == eftAll) {
                    return;
                }
                
                ICLDatePickerPopupViewController* datePickerPopup = [ICLDatePickerPopupViewController create:self.filter_currentButton type:dpptSingleDate];
                datePickerPopup.delegate = self;
                datePickerPopup.startDate = [_filterStartDate copy];
                
                [datePickerPopup show];
                
                return;
            }
            
            // filter type changed
            if (newFilterType != _filterType) {
                _filterType = newFilterType;
                
                if (_filterType == eftAll) {
                    _filterStartDate = nil;
                    _filterEndDate = nil;
                }
                
                [self ensureDateValidity];
                [self updateFilterData];
                [self updateFilterDisplay];
            }
        }
    });
}

- (void) datePickerPopupViewControllerDidChangeDates:(ICLDatePickerPopupViewController *)view startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    // if both dates were supplied we were setting up a custom set
    if (startDate && endDate) {
        _filterType = eftCustom;
        _filterStartDate = [startDate copy];
        _filterEndDate = [endDate copy];
    } // if only one date was supplied then update if we are using week or month
    else {
        if (_filterType == eftWeek) {
            _filterStartDate = [startDate startOfWeek];
            _filterEndDate = [startDate endOfWeek];
        }
        else if (_filterType == eftMonth) {
            _filterStartDate = [startDate startOfMonth];
            _filterEndDate = [startDate endOfMonth];
        }
    }
    
    [self ensureDateValidity];
    [self updateFilterData];
    [self updateFilterDisplay];
}

- (void) copyFilterStateFrom:(ICLFilterableViewController*) otherController {
    _filterType = [otherController filterType];
    _filterStartDate = [[otherController filterStartDate] copy];
    _filterEndDate = [[otherController filterEndDate] copy];
    
    [self updateFilterData];
    [self updateFilterDisplay];
}

@end
