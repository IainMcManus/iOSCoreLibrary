Introduction
==============

The iOS Core Library is a collection of useful screens and categories for iOS applications. The GitHub version is not the full library at this point. Overtime I will be cleaning up the code and making it all available.

The library contains the following:
 * Core Data Stack - Complete iCloud + Core Data stack with sample application.
 * Training Overlay - App training system which overlays the training information onto the UI.
 * Dropbox Uploader - Simple wrapper for the Dropbox upload process that provides a progress indicator.
 * Alert View - Custom UI Alert View control.
 * Colour Picker - iPad/iPhone compatible colour picker.
 * Schedule Helper - Given a schedule (weekly, monthly etc) it generates all scheduled dates between two dates.
 * Custom Categories
   * NSDate
     * Methods to round time to start/end of the day
     * Methods to convert from a provided date to the start/end of the week it belongs to
     * Methods to convert from a provided date to the start/end of the month
     * Methods to take a date and move a week forward/back
     * Methods to take a date and move a month forward/back
   * UIButton
     * Category to apply a glass style to buttons.
   * UIColor
     * Conversions to/from strings
     * Perceived brightness calculation
     * Automatic generation of different shades
   * UITextField
     * Helper for comparison to regex
   * UIViewController
     * Helpers to retrieve the topmost view controller
 * Sample application showing how to use the Core Data stack and some selected other code
 * Third Party Code
   * Reachability code from Apple. The code is provided in full without modifications. Copyright for the code belongs to Apple. Please read and abide by their license.
   * UIImageEffects code from Apple. The code is provided in full without modifications. Copyright for the code belongs to Apple. Please read and abide by their license.
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

	- (NSURL*) coreDataModelURL {
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
	
	- (void) prepareForMigration {
		// TODO - Perform any required changes to the current data before the migration is performed
	}
	
It is very important that when using the library any calls you make using the managed object context are executed on the context's queue. To do that use performBlock/performBlockAndWait. The core data stack provides wrappers for these methods which you should always use. For example:

    // Synchronously execute code that uses the context
    [[ICLCoreDataManager Instance] performBlockAndWait:^{
        // Insert your code here
    }];
    
    // Asynchronously execute code that uses the context
    [[ICLCoreDataManager Instance] performBlock:^{
        // Insert your code here
    }];


Training Overlays
===============

The Training Overlay system creates and draws one or more training overlays for a screen. The training overlay can highlight specific portions of the user interface (eg. a button). You can see an example overlay in the screenshot below:

![Training Overlay (iPad)](/Screenshots/TrainingOverlay_iPad.png?raw=true "Training Overlay (iPad)")

The Training Overlay system automatically tracks which screens have been displayed (based on their name) and will not attempt to show a previously shown screen.

## Setting up the Training Overlay System

The text for the training overlay screens is handled by generating HTML. It uses a style sheet (CSS) to handle the majority of the per-device differences.

Before you can use the Training Overlays you must provide both the location and name of the style sheet. An example of this (from the sample app) is shown below:

    // Let the training system know where the CSS files are stored. In this case in the main bundle for the app.
    [ICLTrainingOverlayInstance setBaseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    
    // If we are running on an iPad load the iPad specific style sheet
    if (Using_iPad) {
    	[ICLTrainingOverlayInstance setCSSName:@"ICLTrainingOverlay_iPad.css"];
    } // Otherwise load the iPhone specific style sheet
    else {
    	[ICLTrainingOverlayInstance setCSSName:@"ICLTrainingOverlay_iPhone.css"];
    }

The code above must be performed before you attempt to show an overlay. Otherwise, the overlay will not generate correctly.

## Registering an Overlay

For each overlay that you wish to display you need to create an ICLTrainingOverlayData object by calling the registerScreen method on ICLTrainingOverlayInstance.

The registration sets up a unique screen instance (based on the supplied name) and sets the title and description text. 

The syntax for the registerScreen method is:

	- (ICLTrainingOverlayData*) registerScreen:(NSString*) screen
									 titleText:(NSString*) titleText
								   description:(NSString*) descriptionText;

 * **screen** is a string which uniquely identifies the particular overlay. Each overlay must have a unique identifier.
 * **titleText** is a string to display as the title of the overlay. It can be empty but cannot be nil.
 * **descriptionText** is a string to display under the title. eg. an explanation of what the screen does. It can be empty but cannot be nil.
 
An example, from the sample app is shown below:

	ICLTrainingOverlayData* overlay = nil;

	// Register the overlay
	overlay = [ICLTrainingOverlayInstance registerScreen:@"PetsTab1"
											   titleText:@"Pets Overview"
											 description:@"This screen lists all of the pets. From here you can add, update or remove a pet entry."];

	[overlay addElement:@[self.mainNavigationBar, self.addPetButton]
			description:@"Tap here to add a new pet."];

## Adding Elements to an Overlay

Once you have registered an overlay then, if required, you can add elements to the overlay. An element is one or more UI elements and an associated description. 

The currently supported elements are:
 * Any control based off of UIView (eg. UILabel, UIButton, UISwitch, UITableViewCell etc)
 * UITabBarItem
 * UINavigationItem
 * UIBarButtonItem
 * UISegmentedControl
 
Elements are added using the method (on ICLTrainingOverlayData) below:

	- (void) addElement:(NSObject*) element description:(NSString*) elementDescription;

 * **element** must be one of:
   * A control based off of UIView.
   * An array with 2 or more controls based off of UIView.
   * An array where the first element is a UITabBar, UIToolBar or UINavigationBar and the second item is a UITabBarItem, UIBarButtonItem or UINavigationItem.
   * An array where the first element is a UISegmentedControl and the second element is a NSNumber of the segment index (0 based) to highlight.
   * [NSNull null] **(not nil)** to add an element that will have a description and a colour associated with it but will not highlight an area.
 * **elementDescription** is the text to associate with the element

The code below (from the sample app) shows how to add an element that is an item in a navigation bar

	[overlay addElement:@[self.mainNavigationBar, self.addPetButton]
			description:@"Tap here to add a new pet."];

You can also add an unhighlighted element. An unhighlighted element does not have a colour or description but it will cut out the background. To add an unhighlighted element use this method:

	- (void) addUnhighlightedElement:(NSObject*) element;

 * **element** follows the same rules as for the addElement method:
   * A control based off of UIView.
   * An array with 2 or more controls based off of UIView.
   * An array where the first element is a UITabBar, UIToolBar or UINavigationBar and the second item is a UITabBarItem, UIBarButtonItem or UINavigationItem.
   * An array where the first element is a UISegmentedControl and the second element is a NSNumber of the segment index (0 based) to highlight.
   * [NSNull null] **(not nil)** to add an element that will have a description and a colour associated with it but will not highlight an area.

## Showing an Overlay

Once you are ready to show an overlay you can use one of these two methods:

	- (BOOL) showScreen:(NSString*) screen forceReshow:(BOOL) forceReshow currentViewController:(UIViewController*) currentVC displayPosition:(DisplayPosition) displayPosition;
	- (BOOL) showScreen:(NSString*) screen forceReshow:(BOOL) forceReshow currentViewController:(UIViewController*) currentVC webViewRect:(NSValue*) webViewRect;

The first (and recommended) method allows you to specific the location of the text using one of the values in the DisplayPosition enumeration. The second method allows you to specific the exact bounding rectangle for the overlay text.

 * **screen** is the name of the screen to show. It is the same as the unique name you provide when you register the screen.
 * **forceReshow** should be YES if you want to reshow the screen even if it has already been shown. Otherwise set it to NO.
 * **currentVC** is the current view controller that is requesting the display of the overlay.
 * **webViewRect** is the bounding rectangle to use as the frame of the overlay text.
 * **displayPosition** is one of the following values:
   * *edpNone* - the overlay will be centred on the screen.
   * *edpLeft* - the overlay will use the full height of the left half of the screen.
   * *edpLeft_Quarter* - the overlay will use the full height of the left 1/4 of the screen.
   * *edpLeft_Third* - the overlay will use the full height of the left 1/3 of the screen.
   * *edpLeft_TwoThirds* - the overlay will use the full height of the left 2/3 of the screen.
   * *edpLeft_ThreeQuarters* - the overlay will use the full height of the left 3/4 of the screen.
   * *edpRight* - the overlay will use the full height of the right half of the screen.
   * *edpRight_Quarter* - the overlay will use the full height of the right 1/4 of the screen.
   * *edpRight_Third* - the overlay will use the full height of the right 1/3 of the screen.
   * *edpRight_TwoThirds* - the overlay will use the full height of the right 2/3 of the screen.
   * *edpRight_ThreeQuarters* - the overlay will use the full height of the right 3/4 of the screen.
   * *edpTop* - the overlay will use the full width of the top half of the screen.
   * *edpTop_Quarter* - the overlay will use the full width of the top 1/4 of the screen.
   * *edpTop_Third* - the overlay will use the full width of the top 1/3 of the screen.
   * *edpTop_TwoThirds* - the overlay will use the full width of the top 2/3 of the screen.
   * *edpTop_ThreeQuarters* - the overlay will use the full width of the top 3/4 of the screen.
   * *edpBottom* - the overlay will use the full width of the bottom half of the screen.
   * *edpBottom_Quarter* - the overlay will use the full width of the bottom 1/4 of the screen.
   * *edpBottom_Third* - the overlay will use the full width of the bottom 1/3 of the screen.
   * *edpBottom_TwoThirds* - the overlay will use the full width of the bottom 2/3 of the screen.
   * *edpBottom_ThreeQuarters* - the overlay will use the full width of the bottom 3/4 of the screen.
   
Multiple screens can be requested to show at the same time. If a screen is already being shown then any other screens will be queued and automatically displayed when the previous ones in the queue are shown.

## Flagging Individual Screens as Shown or Not Shown

The Training Overlay system provides two methods (flagAsShown and flagAsNotShown) which can flag individual screens as shown or not shown. The syntax for these methods is:

	- (void) flagAsShown:(NSArray*) screenNames;
	- (void) flagAsNotShown:(NSArray*) screenNames;
	
 * **screenNames** is an array of the unique screen names to flag as shown or not shown.

## Clearing all Previously Shown Flags

The Training Overlay system automatically keeps track of which screens have been shown and saves this information to the user defaults.

If you need to clear any previously shown flags for any reason then you can do so by calling this method:

	[ICLTrainingOverlayInstance debug_ClearPreviouslyShownFlags];
	
You may need to restart the app for the method to take effect if it has already attempted to show a screen.

## Testing if a Screen Already Exists

If you need to determine if a screen has already been registered (sometimes necessary for more dynamic overlays) then you can use the method below:

	- (BOOL) isScreenRegistered:(NSString*) screen;

 * **screen** is the unique name (provided in registerScreen) for the screen. If that screen has already been registered then it will return YES, otherwise it will return NO.
 
## Pausing/Resuming Overlay Display

Sometimes it is necessary to be able to pause (and resume) the display of overlays. For example if you are waiting for remote data to synchronise to update the UI.

The Training Overlay system supports a delegate (shown below) which makes this possible:

	@protocol ICLTrainingOverlayDelegate <NSObject>

	@required

	- (void) currentOverlaySequenceComplete;
	- (BOOL) readyToShowOverlays;

	@end;

The **readyToShowOverlays** method will be called before any attempt to show a screen. If it returns YES then the overlay will be displayed, otherwise it will be queued.

To resume displaying queued overlays you must call **resumeShowingOverlays** on the ICLTrainingOverlayInstance. That will immediately start showing overlay screens and the first queued screen will be shown.

Once all queued overlays have been shown and dismissed (or if none were queued after the current overlay is dismissed) then the **currentOverlaySequenceComplete** method on the delegate will be called.

To provide a delegate to the Training Overlay system you need to assign a compatible class (one that implements ICLTrainingOverlayDelegate) to the **delegate** variable on ICLTrainingOverlayInstance.

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

    NSDictionary* appearance = @{kICLMeterColour: [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f],
                                 kICLMeterColourForFailure: [UIColor colorWithHue:0.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f],
                                 kICLMeterColourForSuccess: [UIColor colorWithHue:120.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f]};

    ICLUploadToDropboxViewController* uploadController = nil;
    uploadController = [ICLUploadToDropboxViewController create:@"sourceFile.zip"
                                                destinationPath:@"/Backup/"
                                              appearanceOptions:appearance];

![Dropbox Upload in Progress (iPad)](/Screenshots/iPad_DropboxUpload_InProgress.png?raw=true "Dropbox Upload in Progress (iPad)") 
![Dropbox Upload in Progress (iPhone)](/Screenshots/iPhone_DropboxUpload_InProgress.png?raw=true "Dropbox Upload in Progress (iPhone)")

Alert View
===============

The Alert View (ICLAlertViewController) is a larger version of the UIAlertView which supports some visual customisation. It is intended for cases where you need a user to make a choice where the different options require a longer explanation. For example, I use the ICLAlertViewController in the Core Data stack when prompting the user if they want to use iCloud or Local storage.

Currently the ICLAlertViewController supports:
 * iPhone and iPad
 * iOS 6 and above
 * 2 or 3 options (1 option or more than 3 options are not currently supported)
 * Customising the panel and button colour
 
To construct the alert view you must provide:
 * The title for the view
 * 2 or 3 option names (provided as an array of strings)
 * 2 or 3 option descriptions (provided as an array of strings)
 * A dictionary of customisation options, the settings you can customise are:
   * Button1Colour - UIColor to use for the button for the first option
   * Button2Colour - UIColor to use for the button for the second option
   * Button3Colour - UIColor to use for the button for the third option
   * Panel1Colour - UIColor to use for the panel for the first option
   * Panel2Colour - UIColor to use for the panel for the second option
   * Panel3Colour - UIColor to use for the panel for the third option
   * BackgroundImage - Name of the image to use for the background (or an empty string for no image)
 
Example of setting up the ICLAlertViewController

 	// Setup the colours for use with the alert view
	UIColor* button1Colour = [UIColor colorWithHue:220.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
	UIColor* button2Colour = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
	UIColor* panel1Colour = [UIColor colorWithHue:210.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
	UIColor* panel2Colour = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
	
	// Construct the alert view
	ICLAlertViewController* alertView = [ICLAlertViewController create:@"Alert View Title"
							  				   			   optionNames:@[@"Option 1", @"Option 2"]
													optionDescriptions:@[@"Option 1 Description", @"Option 2 Description"]
										 		 	 appearanceOptions:@{kICLButton1Colour: button1Colour,
																		 kICLButton2Colour: button2Colour,
																		 kICLPanel1Colour: panel1Colour,
																		 kICLPanel2Colour: panel2Colour,
																		 kICLBackgroundImage: @""}];
	
	// Set this object as the delegate which conforms to the ICLAlertViewControllerDelegate protocol											 
	alertView.delegate = self;
	
	// Show the alert view
	[alertView show];

The ICLAlertViewController will call the alertViewControllerDidFinish method on the provided delegate after the view is dismissed. alertViewControllerDidFinish provides both the alertView which finished and the option (1, 2 or 3) that the user selected.

	- (void)alertViewControllerDidFinish:(ICLAlertViewController *)alertView selectedOption:(NSUInteger)option {
		NSLog(@"User selected option %d for %@", option, alertView);
	}

Colour Picker
===============

The colour picker is an iPhone/iPad compatible view which allows users to pick a colour. The colour picker contains:
 * A colour wheel which the user can tap to select a specific colour (based on hue and saturation)
 * Red, Green and Blue component sliders for adjusting the individual values
 * Red, Green and Blue component text fields for direct entry of the individual values
 * Brightness slider
 
The colour picker is compatible with iPad and iPhone and has been tested on iOS 6 and above. An example of using the colour picker is provided in [Colour Picker Example](/iOSCoreLibrarySampleApp/iOSCoreLibrarySampleApp/Source/View%20Controllers/Miscellaneous/ISAMiscellaneousTabViewController.m)

Schedule Helper
===============

The Schedule Helper class (ICLScheduleHelper) provides a single interface that returns an array of the corresponding NSDate objects:

	+ (NSArray*) generateScheduleDates:(NSDictionary*) repeatConfig
							  fromDate:(NSDate*) fromDate
								toDate:(NSDate*) toDate;
								
The range in which the scheduled dates are generated is defined (inclusively) by *fromDate* and *toDate*. 

The repeatConfig describes the schedule itself. The repeat config is a dictionary which must contain the following keys:

 * kICLSchedule_StartDate - this is the date that the schedule begins. (Value must be an NSDate)
 * kICLSchedule_EndDate - this is the last day that the schedule can occur. (Value must be an NSDate)
 * kICLSchedule_Options - describes additional details for the schedule (eg. the days of the week it occurs) (Value must be an NSArray. It can be empty but not nil).
 * kICLSchedule_Type - this is the (repeat) type for the schedule. The value is an NSNumber corresponding to one of:
   * estNever - Never repeats.
   * estDaily - Repeats the same days each week (eg. every Monday and Thursday).
   * estWeekly - Repeats on the same day each week (eg. every Wednesday).
   * estFortnightly - Repeats on the same day every 2 weeks (eg. every second Tuesday).
   * estMonthly - Repeats every month on the same day (or the closest day to it).
   * estQuarterly - Repeats every 3 months.
   * estAnnually - Repeats every year on the same day (or the closest day to it).
   
For the Daily, Weekly and Fortnightly schedules the kICLSchedule_Options key corresponds to an NSArray that defines which days the schedule will repeat on. For the weekly and fortnightly options only the first value in the array will be used. The array elements must be NSNumbers that correspond to one of:

   * edsoSunday
   * edsoMonday
   * edsoTuesday
   * edsoWednesday
   * edsoThursday
   * edsoFriday
   * edsoSaturday
   
For schedules that correspond to a specific day in the month (eg. monthly, quarterly or annually) the Schedule Helper will automatically handle clamping the day to the correct month. For example a monthly event that is set to repeat on the 31st of the month will clamp to the 30th (or earlier for February) as appropriate.

For examples on using the Schedule Helper there are a set of unit tests that cover every schedule type in [Schedule Helper Unit Tests](/iOSCoreLibrarySampleApp/iOSCoreLibrarySampleAppTests/ICLScheduleHelper_Tests.m)

Categories
===============

## NSDate+Extensions
Provides a range of helper methods to manipulate an NSDate object.

Usage

	#import <iOSCoreLibrary/NSDate+Extensions.h>
	
	NSDate* currentDate = [NSDate date]
	
	// Floors the time component of the date (ie. set to 0:00)
	NSDate* flooredDate = [currentDate dateFloor];
	
	// Ceils the time component of the date (ie. set to 23:59:59)
	NSDate* ceiledDate = [currentDate dateCeil];
	
	// Returns an NSDate for the start of the week relative to the provided date
	NSDate* startOfWeek = [currentDate startOfWeek];
	
	// Returns an NSDate for the end of the week relative to the provided date
	NSDate* endOfWeek = [currentDate endOfWeek];
	
	// Returns an NSDate for the start of the month relative to the provided date
	NSDate* startOfMonth = [currentDate startOfMonth];
	
	// Returns an NSDate for the end of the month relative to the provided date
	NSDate* endOfMonth = [currentDate endOfMonth];
	
	// Returns an NSDate for 1 week before the provided date
	NSDate* previousWeek = [currentDate previousWeek];
	
	// Returns an NSDate for 1 week after the provided date
	NSDate* nextWeek = [currentDate nextWeek];
	
	// Returns an NSDate for the day before the provided day
	NSDate* previousDay = [currentDate previousDay];
	
	// Returns an NSDate for the day after the provided date
	NSDate* nextDay = [currentDate nextDay];
	
	// Returns an NSDate for 1 month before the provided date
	// The day component will be clamped to lie within the valid range for that month
	NSDate* previousMonth = [currentDate previousMonth];
	
	// Returns an NSDate for 1 month after the provided date
	// The day component will be clamped to lie within the valid range for that month
	NSDate* nextMonth = [currentDate nextMonth];
	
	// Returns an NSDate for 2 months before the provided date
	// The day component will be clamped to lie within the valid range for that month
	NSDate* previousMonth = [currentDate previousMonth:2];
	
	// Returns an NSDate for 2 months after the provided date
	// The day component will be clamped to lie within the valid range for that month
	NSDate* nextMonth = [currentDate nextMonth:2];
	
	// Returns an NSDate for January 1st in the year of the provided date
	NSDate* startOfYear = [currentDate startOfYear];
	
	// Returns an NSDate for December 31st in the year of the provided date
	NSDate* endOfYear = [currentDate endOfYear];
	
	// Returns YES if the provided date is between the two provided dates
	if ([currentDate isBetweenDates:startOfWeek endDate:endOfWeek]) {
	}

## UIButton+applyGlassStyle
Applies a basic glass look to a UIButton which has been set to custom drawing. In iOS 6 the button corners are rounded, in iOS 7 they will be square.

Usage

    #import <iOSCoreLibrary/UIButton+applyGlassStyle.h>

    // Apply the glass style to the done button using small corners on iOS 6
    // Also supported are medium (egbsMedium) and large (egbsLarge) rounded corners.
    UIColor* buttonColour = [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f];
    [self.doneButton applyGlassStyle:egbsSmall colour:buttonColour];

    // Applies the glass style and autocolours the text based on the perceived brightness of the colour    
    [self.doneButton applyGlassStyle:egbsSmall colour:buttonColour autoColourText:YES];

    
## UIColor+extensions
Provides a set of routines to perform common manipulations on UIColor.

Usage

    #import <iOSCoreLibrary/UIColor+extensions>
    
    UIColor* buttonColour = [UIColor colorWithHue:240.0f/360.0f saturation:0.5f brightness:0.95f alpha:1.0f];
    
    // Generates a hex string (#RRGGBBAA) representation of the colour
    NSString* hexButtonColour = [buttonColour hexString];
    
    // Generates a HTML style hex string (#RRGGBB) representation of the colour
    NSString* hexButtonColour = [buttonColour htmlHexString];
    
    // Converts from a hex string to a UIColor
    UIColor* buttonColour2 = [UIColor fromHexString:hexButtonColour];
    
    // Calculates the perceived brightness (0 to 1) of a colour. 0 indicates black and 1 indicates white.
    CGFloat perceivedBrightness = [buttonColour perceivedBrightness];
    
    // Attempts to generate a different shade of the same colour. The new colour may be lighter or darker.
    UIColor* Colour = [buttonColour autoGenerateDifferentShade];
    
    // Generates a slightly lighter shade of the colour.
    UIColor* Colour = [buttonColour autoGenerateLighterShade];
    
    // Generates a significantly lighter shade of the colour.
    UIColor* Colour = [buttonColour autoGenerateMuchLighterShade];

## UITextField+matchesRegex
Provides a single method that indicates if the current content of the field matches the supplied regex.

Usage

    #import <iOSCoreLibrary/UITextField+matchesRegex.h>
    
    NSString* validRGBRegex = @"^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$";
    
    // Check if the red value text field contains an invalid value (0-255).
    if (![self.redField matchesRegex:validRGBRegex]) {
    }

## UIViewController+extensions
Retrieves the top level view controller when provided with an existing controller. The original source for this section of code was StackOverflow in this question http://stackoverflow.com/questions/6131205/iphone-how-to-find-topmost-view-controller

    #import <iOSCoreLibrary/UIButton+Extensions.h>

    // Call from within any view controller to retrieve the topmost one.
    // Currently used by the Dropbox view after it creates it's View Controller but prior to it being displayed.
    UIViewController* topVC = [self topViewController];
