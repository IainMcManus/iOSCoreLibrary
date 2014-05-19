Introduction
==============

The iOS Core Library is a collection of useful screens and categories for iOS applications. The GitHub version is not the full library at this point. Overtime I will be cleaning up the code and making it all available.

Screens
===============

## Dropbox Uploader
This is a simple wrapper for the Dropbox upload process. It handles uploading a single file to Dropbox and displays a progress indicator.

Features
 * Supports iPhone/iPad for iOS 6 +
 * Displays percentage progress of the upload
 * Reports upload errors to the user and permits retrying
 
Requirements
 * You will need the official Dropbox SDK and must run through their setup steps
 * The Dropbox SDK must be added as a Framework to the iOSCoreLibrary project
 * Refer to https://www.dropbox.com/developers/core/sdks/ios for more information
 
Usage
    #import <iOSCoreLibrary/ICLUploadToDropboxViewController.h>

    NSDictionary* appearance = @{@"MeterColour": [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f],
                                 @"MeterColourForFailure": [UIColor colorWithHue:0.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f],
                                 @"MeterColourForSuccess": [UIColor colorWithHue:120.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f]};

    ICLUploadToDropboxViewController* uploadController = nil;
    uploadController = [ICLUploadToDropboxViewController create:@"Upload to Dropbox"
                                                     sourceFile:@"sourceFile.zip"
                                                destinationPath:@"/Backup/"
                                              appearanceOptions:appearance
                                                     errorTitle:@"Upload Error"
                                                   errorMessage:@"Upload failed!"
                                                      retryText:@"Retry"
                                                     cancelText:@"Cancel"];


Categories
===============

## UIButton - Apply Glass Style
Applies a basic glass look to a UIButton which has been set to custom drawing. In iOS 6 the button corners are rounded, in iOS 7 they will be square.

Usage
    #import <iOSCoreLibrary/UIButton+applyGlassStyle.h.h>

    # Apply the glass style to the done button using small corners on iOS 6
    # Also supported are medium (egbsMedium) and large (egbsLarge) rounded corners.
    UIColor* buttonColour = [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f];
    [self.doneButton applyGlassStyle:egbsSmall colour:buttonColour];
    

## UIViewController - Retrieve Top Level View Controller
    #import <iOSCoreLibrary/UIButton+Extensions.h.h>

    # Call from within any view controller to retrieve the topmost one.
    # Currently used by the Dropbox view after it creates it's View Controller but prior to it being displayed.
    UIViewController* topVC = [self topViewController];
