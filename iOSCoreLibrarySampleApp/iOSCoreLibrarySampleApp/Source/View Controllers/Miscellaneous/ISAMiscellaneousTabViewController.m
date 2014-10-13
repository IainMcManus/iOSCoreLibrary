//
//  ISAMiscellaneousTabViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 25/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAMiscellaneousTabViewController.h"

#import <iOSCoreLibrary/UIButton+applyGlassStyle.h>
#import <iOSCoreLibrary/ICLColourPickerViewController.h>

@interface ISAMiscellaneousTabViewController () <ICLColourPickerViewControllerDelegate, UIPopoverControllerDelegate>

@end

@implementation ISAMiscellaneousTabViewController {
    ICLColourPickerViewController* colourPicker;
    UINavigationController* colourSelectorNavController;
    
    UIPopoverController* colourSelectorPopover;
    
    UIColor* workingColour;
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
    
    workingColour = [UIColor colorWithHue:227.0f/360.0f saturation:0.63f brightness:0.75f alpha:1.0f];
    
    [self.selectColourButton applyGlassStyle:egbsSmall colour:workingColour autoColourText:YES];
    [self.resetTrainingButton applyGlassStyle:egbsSmall colour:workingColour autoColourText:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)selectColour:(id)sender {
    // Create a new instance of the picker view controller
    colourPicker = [ICLColourPickerViewController create];
    colourPicker.delegate = self;
    
    // Set the current settings
    colourPicker.TitleText  = NSLocalizedStringFromTable(@"Category.Colour", @"Categories", @"Category Colour");
    colourPicker.CurrentColour = [workingColour copy];
    colourPicker.BackgroundImage = @"";
    colourPicker.BackgroundImageAlpha = 0.4f;
    
    // Setup a navigation controller for the picker view
    colourSelectorNavController = [[UINavigationController alloc] initWithRootViewController:colourPicker];
    [colourSelectorNavController setNavigationBarHidden:YES];
    
    if (Using_iPad) {
        // Create the popover
        colourSelectorPopover = [[UIPopoverController alloc] initWithContentViewController:colourSelectorNavController];
        [colourSelectorPopover setDelegate:self];
        
        CGRect buttonRect = self.selectColourButton.frame;
        [colourSelectorPopover presentPopoverFromRect:buttonRect
                                               inView:self.view
                             permittedArrowDirections:UIPopoverArrowDirectionLeft
                                             animated:YES];
    }
    else {
        // show the colour selector
        [self presentViewController:colourSelectorNavController animated:YES completion:nil];
    }
}

- (IBAction)resetTraining:(id)sender {
    [ICLTrainingOverlayInstance debug_ClearPreviouslyShownFlags];
    
    [[[UIAlertView alloc] initWithTitle:@"Overlays Reset" message:@"All training overlays will now reshow when you restart the app." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

#pragma mark UIPopoverControllerDelegate Support

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [colourPicker dismissViewControllerAnimated:YES completion:nil];
    [colourPicker.view removeFromSuperview];
    [colourSelectorPopover dismissPopoverAnimated:YES];
    
    colourPicker = nil;
    colourSelectorNavController = nil;
    colourSelectorPopover = nil;
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

#pragma mark ICLColourPickerViewControllerDelegate Support

- (void) colourPickerViewController:(ICLColourPickerViewController*) viewController didSelectColour:(UIColor*) colour {
    workingColour = [colourPicker.CurrentColour copy];
    
    [self.selectColourButton applyGlassStyle:egbsSmall colour:workingColour autoColourText:YES];
    
    if (Using_iPad) {
        [colourSelectorPopover dismissPopoverAnimated:YES];
    }
    else {
        [viewController dismissViewControllerAnimated:YES completion:nil];
        
        colourPicker = nil;
        colourSelectorNavController = nil;
    }
}

- (void) colourPickerViewControllerDidCancel:(ICLColourPickerViewController*) viewController {
    if (Using_iPad) {
        [colourSelectorPopover dismissPopoverAnimated:YES];
    }
    else {
        [viewController dismissViewControllerAnimated:YES completion:nil];
        
        colourPicker = nil;
        colourSelectorNavController = nil;
    }
}

@end
