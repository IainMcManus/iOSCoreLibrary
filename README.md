Introduction
==============

The iOS Core Library is a collection of useful screens and categories for iOS applications. The GitHub version is not the full library at this point. Overtime I will be cleaning up the code and making it all available.

The library contains the following:
 * Dropbox Uploader - Simple wrapper for the Dropbox upload process that provides a progress indicator.
 * Alert View - Custom UI Alert View control.
 * Core Data Stack - Complete iCloud + Core Data stack.
 * Custom Categories
   * UIButton+applyGlassStyle
   * UIColor+extensions
   * UIViewController+extensions
 * Internal Categories
   * NSBundle+InternalExtensions
   * NSURL+InternalExtensions
 * Third Party Code
   * Reachability code from Apple. The code is provided in full without modifications. Copyright for the code belongs to Apple. Please read and abide by their license.
   * KCOrderedAccessorFix from https://github.com/CFKevinRef/KCOrderedAccessorFix. Copyright for the code belongs to Kevin Cassidy Jr. Please read and abide by their license.

Core Data Stack
===============

This is a complete iCloud + Core Data stack for iOS 7+. It handles setting up, importing initial data, migrating existing data and enabling/disabling iCloud.

I have fully documented the code at http://iaintheindie.com/2014/07/07/icloud-core-data-part-3-complete-stack/

Dropbox Uploader
===============

This is a simple wrapper for the Dropbox upload process. It handles uploading a single file to Dropbox and displays a progress indicator.

Features
 * Supports iPhone/iPad for iOS 6 +
 * Displays percentage progress of the upload
 * Reports upload errors to the user and permits retrying
 
Requirements
 * You will need the official Dropbox SDK and must run through their setup steps
 * You will need to add the CoreImage and OpenGLES frameworks to your project
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

![Dropbox Upload in Progress (iPad)](/Screenshots/iPad_DropboxUpload_InProgress.png?raw=true "Dropbox Upload in Progress (iPad)") 
![Dropbox Upload Successful (iPad)](/Screenshots/iPad_DropboxUpload_Success.png?raw=true "Dropbox Upload Successful (iPad)")
![Dropbox Upload in Progress (iPhone)](/Screenshots/iPhone_DropboxUpload_InProgress.png?raw=true "Dropbox Upload in Progress (iPhone)")
![Dropbox Upload Successful (iPhone)](/Screenshots/iPhone_DropboxUpload_Success.png?raw=true "Dropbox Upload Successful (iPhone)") 

Categories
===============

## UIButton+applyGlassStyle
Applies a basic glass look to a UIButton which has been set to custom drawing. In iOS 6 the button corners are rounded, in iOS 7 they will be square.

Usage

    #import <iOSCoreLibrary/UIButton+applyGlassStyle.h>

    # Apply the glass style to the done button using small corners on iOS 6
    # Also supported are medium (egbsMedium) and large (egbsLarge) rounded corners.
    UIColor* buttonColour = [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f];
    [self.doneButton applyGlassStyle:egbsSmall colour:buttonColour];
    
## UIColor+extensions
Provides a set of routines to perform common manipulations on UIColor.

Usage

    #import <iOSCoreLibrary/UIColor+extensions>
    
    UIColor* buttonColour = [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f];
    
    # Generates a HTML style hex string (#RRGGBBAA) representation of the colour
    NSString* hexButtonColour = [buttonColour hexString];
    
    # Converts from a hex string to a UIColor
    UIColor* buttonColour2 = [UIColor fromHexString:hexButtonColour];
    
    # Calculates the perceived brightness (0 to 1) of a colour. 0 indicates black and 1 indicates white.
    CGFloat perceivedBrightness = [buttonColour perceivedBrightness];
    
    # Attempts to generate a different shade of the same colour. The new colour may be lighter or darker.
    UIColor* Colour = [buttonColour autoGenerateDifferentShade];
    
    # Generates a slightly lighter shade of the colour.
    UIColor* Colour = [buttonColour autoGenerateLighterShade];
    
    # Generates a significantly lighter shade of the colour.
    UIColor* Colour = [buttonColour autoGenerateMuchLighterShade];

## UIViewController+extensions
Retrieves the top level view controller when provided with an existing controller. The original source for this section of code was StackOverflow in this question http://stackoverflow.com/questions/6131205/iphone-how-to-find-topmost-view-controller

    #import <iOSCoreLibrary/UIButton+Extensions.h>

    # Call from within any view controller to retrieve the topmost one.
    # Currently used by the Dropbox view after it creates it's View Controller but prior to it being displayed.
    UIViewController* topVC = [self topViewController];
