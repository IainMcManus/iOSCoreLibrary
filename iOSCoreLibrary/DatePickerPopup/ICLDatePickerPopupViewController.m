//
//  ICLDatePickerPopupViewController.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 17/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLDatePickerPopupViewController.h"
#import "UIViewController+Extensions.h"
#import "ICLDatePickerTransition.h"

@interface ICLDatePickerPopupViewController () <UIPopoverControllerDelegate, UIViewControllerTransitioningDelegate>

@end

@implementation ICLDatePickerPopupViewController {
    UINavigationController* _navigationViewController;
    UIPopoverController* _popoverViewController;
}

+ (id) create:(UIBarButtonItem*) buttonItem type:(DatePickerPopupType) type {
    NSBundle* libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"iOSCoreLibraryBundle" withExtension:@"bundle"]];
    
    ICLDatePickerPopupViewController* viewController = nil;
    
    if (type == dpptSingleDate) {
        viewController = [[ICLDatePickerPopupViewController alloc] initWithNibName:@"ICLDatePickerPopupViewController" bundle:libBundle];
    }
    else {
        viewController = [[ICLDatePickerPopupViewController alloc] initWithNibName:@"ICLDatePickerPopupViewController_2Dates" bundle:libBundle];
    }
    
    viewController.buttonItem = buttonItem;
    viewController.datePickerPopupType = type;
    
    return viewController;
}

- (void) show {
    // Setup a navigation controller for the picker view
    _navigationViewController = [[UINavigationController alloc] initWithRootViewController:self];
    [_navigationViewController setNavigationBarHidden:YES];
    
    UIViewController* activeVC = [self topViewController];
    
    if (Using_iPad) {
        // Create the popover
        _popoverViewController = [[UIPopoverController alloc] initWithContentViewController:_navigationViewController];
        [_popoverViewController setDelegate:self];
        
        [_popoverViewController presentPopoverFromBarButtonItem:self.buttonItem permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        
        [self.view setBackgroundColor:[UIColor clearColor]];
    }
    else {
        // transitioning delegates are only available on iOS 7
        if (Using_iOS7OrAbove) {
            if (self.datePickerPopupType == dpptSingleDate) {
                _navigationViewController.transitioningDelegate = self;
                _navigationViewController.modalPresentationStyle = UIModalPresentationCustom;
                _navigationViewController.view.frame = CGRectMake(0, 0, 320.0f, 265.0f);
            }
        }
        
        [self.view setBackgroundColor:[UIColor colorWithWhite:0.9f alpha:0.95f]];
        
        [activeVC presentViewController:_navigationViewController animated:YES completion:nil];
    }
    
    if (self.startDate) {
        [self.startDatePicker setDate:self.startDate];
    }
    
    if (self.datePickerPopupType == dpptStartAndEndDate) {
        [self.endDatePicker setDate:self.endDate ? self.endDate : [self.startDate copy]];
    }
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
    
    CGFloat viewWidth = 320.0f;
    CGFloat viewHeight = self.datePickerPopupType == dpptSingleDate ? 265.0f : 478.0f;
    
    if (Using_iPad) {
        CGSize contentSize = CGSizeMake(viewWidth, viewHeight);
        
        // set content size for versions < iOS 7
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7) {
            self.contentSizeForViewInPopover = contentSize;
        } // iOS7 and above
        else {
            self.preferredContentSize = contentSize;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    ICLDatePickerTransition* transition = [ICLDatePickerTransition new];
    transition.isPresenting = YES;
    
    return transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    ICLDatePickerTransition* transition = [ICLDatePickerTransition new];
    
    return transition;
}

- (IBAction)doneButtonPressed:(id)sender {
    if (Using_iPad) {
        [_popoverViewController dismissPopoverAnimated:YES];
        
        _navigationViewController = nil;
        _popoverViewController = nil;
        
        if (self.datePickerPopupType == dpptSingleDate) {
            [self.delegate datePickerPopupViewControllerDidChangeDates:self startDate:self.startDatePicker.date endDate:nil];
        }
        else {
            [self.delegate datePickerPopupViewControllerDidChangeDates:self startDate:self.startDatePicker.date endDate:self.endDatePicker.date];
        }
    }
    else {
        [_navigationViewController dismissViewControllerAnimated:YES completion:^{
            if (self.datePickerPopupType == dpptSingleDate) {
                [self.delegate datePickerPopupViewControllerDidChangeDates:self startDate:self.startDatePicker.date endDate:nil];
            }
            else {
                [self.delegate datePickerPopupViewControllerDidChangeDates:self startDate:self.startDatePicker.date endDate:self.endDatePicker.date];
            }
        }];
    }
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

@end
