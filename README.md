Introduction
==============

The iOS Core Library is a collection of useful screens and categories for iOS applications. The GitHub version is not the full library at this point. Overtime I will be cleaning up the code and making it all available.

The library contains the following:
 * Dropbox Uploader - Simple wrapper for the Dropbox upload process that provides a progress indicator.
 * Alert View - Custom UI Alert View control.
 * Core Data Stack - Complete iCloud + Core Data stack with sample application.
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

A sample application is included (iOSCoreLibrarySampleApp). The sample app has a basic setup of data and shows:
 * Importing existing data to the Core Data stack.
 * Reacting to remote changes to refresh displays or return to the main screen where required.
 * Enabling/disabling iCloud including merging of the data and basic deduplication.

## Requirements
To use the Core Data Stack you must provide a delegate which implements the ICLCoreDataManagerDelegate protocol.

## Using the Stack
During the initialisation of your app (in didFinishLaunchingWithOptions) you must setup the stack. The stack requires:
 * A delegate that implements the ICLCoreDataManagerDelegate protocol.
 * Colour information for the custom alert view.
 * A call to start the loading process.
 
An example of this loading process is shown below: 

    [ICLCoreDataManager Instance].delegate = self;
    
    [ICLCoreDataManager Instance].Colour_AlertView_Button1 = [UIColor colorWithHue:220.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
    [ICLCoreDataManager Instance].Colour_AlertView_Button2 = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
    [ICLCoreDataManager Instance].Colour_AlertView_Panel1 = [UIColor colorWithHue:210.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
    [ICLCoreDataManager Instance].Colour_AlertView_Panel2 = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];

    [[ICLCoreDataManager Instance] requestBeginLoadingDataStore];
    
Once your UI is ready and the Core Data Stack can show UI if required invoke the following method:

    [[ICLCoreDataManager Instance] requestFinishLoadingDataStore];
    
The methods required by the ICLCoreDataManagerDelegate are shown below:

	- (BOOL) performLegacyDataConversionIfRequired {
		// TODO - perform any legacy data conversion.
		// If conversion is performed return YES otherwise return NO.
	
		return NO;
	}

	- (void) loadMinimalDataSet {
		// TODO - Load any initial seed data if required
	}

	- (NSString*) storeName_Local {
		// Replace MyAppName with your app's name (or a similar unique name)
		return @"MyAppName_Local";
	}

	- (NSString*) storeName_iCloud {
		// Replace MyAppName with your app's name (or a similar unique name)
		return @"MyAppName_iCloud";
	}

	- (NSURL*) modelURL {
		// Return the URL for the Core Data model. Replace MyAppCoreData with the name of your model.
		return [[NSBundle mainBundle] URLForResource:@"MyAppCoreData" withExtension:@"momd"];
	}

	- (NSString*) backgroundImageNameForDialogs {
		// TODO - return the name for the background image for the app (or nil for none)
	}

	- (void) contextSaveNotification:(NSNotification*) notification {
	}

	- (void) storeWillChangeNotification {
		// TODO - Cleanup the UI and prepare for all current managed objects to go away
	}

	- (void) storeDidChangeNotification {
		// TODO - Add any custom handling in response to the stores changing
	
		// TODO - Add data de-duplication logic here

		// TODO - Refresh UI    
	}

	- (void) storeDidImportUbiquitousContentChangesNotification:(NSNotification*) notification {
		// TODO - Add data de-duplication logic here
	
		// TODO - Add any custom handling for deleted, added or modified objects
	}
	
It is very important that when using the library any calls you make using the managed object context are executed on the context's queue. To do that use performBlock/performBlockAndWait. For example:

    // Synchronously execute code that uses the context
    [[[ICLCoreDataManager Instance] managedObjectContext] performBlockAndWait:^{
        // Insert your code here
    }];
    
    // Asynchronously execute code that uses the context
    [[[ICLCoreDataManager Instance] managedObjectContext] performBlock:^{
        // Insert your code here
    }];


Dropbox Uploader
===============

This is a simple wrapper for the Dropbox upload process. It handles uploading a single file to Dropbox and displays a progress indicator.

Features
 * Supports iPhone/iPad for iOS 6 +
 * Displays percentage progress of the upload
 * Reports upload errors to the user and permits retrying
 
Requirements
 * You will need to add the CoreImage and OpenGLES frameworks to your project
 * Version 1.3.11 of the Dropbox SDK has been included. For the latest version please go to https://www.dropbox.com/developers/core/sdks/ios
 * The Dropbox SDK is the property of Dropbox Inc. Please refer to their license agreement before modifying or distributing their code.

Enabling Dropbox
 * Dropbox is disabled in the library by default.
 * To enable it open the BuildFlags.h file in the Supporting Files group.
 * Change #define ICL_Using_Dropbox 0 to #define ICL_Using_Dropbox 1 and recompile.
 * Be sure to have the Dropbox SDK included in your application.
 
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
