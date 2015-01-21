//
//  ICLDatePickerPopupViewController.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 17/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    dpptSingleDate,
    dpptStartAndEndDate
} DatePickerPopupType;

@protocol ICLDatePickerPopupViewControllerDelegate;

@interface ICLDatePickerPopupViewController : UIViewController

@property (weak, nonatomic) id <ICLDatePickerPopupViewControllerDelegate> delegate;
@property (strong, nonatomic) NSDate* startDate;
@property (strong, nonatomic) NSDate* endDate;

@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *startDatePicker;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *endDatePicker;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) UIBarButtonItem* buttonItem;
@property (assign, nonatomic) DatePickerPopupType datePickerPopupType;

- (IBAction)doneButtonPressed:(id)sender;

+ (id) create:(UIBarButtonItem*) buttonItem type:(DatePickerPopupType) type;
- (void) show;

@end

@protocol ICLDatePickerPopupViewControllerDelegate <NSObject>

@required

- (void) datePickerPopupViewControllerDidChangeDates:(ICLDatePickerPopupViewController*) view startDate:(NSDate*) startDate endDate:(NSDate*) endDate;

@end;
