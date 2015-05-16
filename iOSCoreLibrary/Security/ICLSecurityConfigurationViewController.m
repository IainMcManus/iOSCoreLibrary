//
//  ICLSecurityConfigurationViewController.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 3/05/2015.
//  Copyright (c) 2015 Iain McManus. All rights reserved.
//

#import "ICLSecurityConfigurationViewController.h"

#import "NSBundle+InternalExtensions.h"
#import "UIColor+extensions.h"
#import "ICLTrainingOverlay.h"
#import "ICLTrainingOverlayData.h"

#import "ABPadLockScreenSetupViewController.h"
#import "ABPadLockScreenView.h"
#import "ABPadButton.h"
#import "KeychainItemWrapper.h"

#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>

NSString* ICL_Security_AppSecuredKey = @"ICL.Security.AppSecured";
NSString* ICL_Security_LastCheckTime = @"ICL.Security.LastCheckTime";
NSString* ICL_Security_TimeBetweenChecks = @"ICL.Security.TimeBetweenChecks";
NSString* ICL_Security_TouchIdEnabled = @"ICL.Security.TouchIdEnabled";

NSString* ICL_Security_Keychain = @"ICL.Security.Passcode";

NSString* ICL_Security_Training_ShownChangePassCode = @"ICL.Security.Training.ShownChangePassCode";
NSString* ICL_Security_Training_ShownToggleTouchId = @"ICL.Security.Training.ShownToggleTouchId";

typedef enum {
    eslLow,
    eslMedium,
    eslHigh
} SecurityLevel;

@interface ICLSecurityConfigurationViewController () <ABPadLockScreenSetupViewControllerDelegate>

@end

@implementation ICLSecurityConfigurationViewController {
    UIWebView* securityStatusWebView;
    
    UIButton* togglePassCodeButton;
    UIButton* setPassCodeButton;
    UIButton* toggleTouchIdButton;
    
    UIColor* defaultButtonColour;
    
    SecurityLevel securityLevel;
    BOOL touchIdAvailable;
    
    KeychainItemWrapper* keychain;
    ABPadLockScreenSetupViewController* setupPinScreen;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    securityLevel = eslLow;
    touchIdAvailable = NO;
    setupPinScreen = nil;

    // Setup the keychain
    keychain = [[KeychainItemWrapper alloc] initWithIdentifier:ICL_Security_Keychain accessGroup:nil];
    [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)(kSecAttrAccessible)];
    
    // Setup the colours
    defaultButtonColour = [UIColor colorWithHue:130.0f/360.0f saturation:0.63f brightness:0.75f alpha:1.0f];
    
    // Create the interface
    [self createInterface];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Common Interfaces for Settings Wizard

- (void) linkToParent {
}

- (void) storeWillChange {
}

- (void) storeDidChange {
}

- (void) refreshIsTouchIdAvailable {
    LAContext *context = [[LAContext alloc] init];
    NSError *touchIdCheckError = nil;
    
    // Check if touch Id is available
    touchIdAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&touchIdCheckError];
}

- (void) refresh {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    // Update TouchId status
    [self refreshIsTouchIdAvailable];
    
    securityLevel = eslLow;
    
    // Update the button text and visibility
    if ([userDefaults boolForKey:ICL_Security_AppSecuredKey]) {
        securityLevel = eslMedium;
        
        [togglePassCodeButton setTitle:NSLocalizedStringFromTableInBundle(@"Setup.DisablePassCode", @"ICL_Security", [NSBundle localisationBundle], @"Disable Pass Code") forState:UIControlStateNormal];
        [setPassCodeButton setTitle:NSLocalizedStringFromTableInBundle(@"Setup.ChangePassCode", @"ICL_Security", [NSBundle localisationBundle], @"Change Pass Code") forState:UIControlStateNormal];
        
        if ([userDefaults boolForKey:ICL_Security_TouchIdEnabled]) {
            securityLevel = eslHigh;
            [toggleTouchIdButton setTitle:NSLocalizedStringFromTableInBundle(@"Setup.DisableTouchId", @"ICL_Security", [NSBundle localisationBundle], @"Disable Touch Id") forState:UIControlStateNormal];
        }
        else {
            [toggleTouchIdButton setTitle:NSLocalizedStringFromTableInBundle(@"Setup.EnableTouchId", @"ICL_Security", [NSBundle localisationBundle], @"Enable Touch Id") forState:UIControlStateNormal];
        }
        
        [setPassCodeButton setHidden:NO];
        [toggleTouchIdButton setHidden:!touchIdAvailable];
    }
    else {
        [togglePassCodeButton setTitle:NSLocalizedStringFromTableInBundle(@"Setup.EnablePassCode", @"ICL_Security", [NSBundle localisationBundle], @"Enable Pass Code") forState:UIControlStateNormal];
        
        [setPassCodeButton setHidden:YES];
        [toggleTouchIdButton setHidden:YES];
    }
    
    [securityStatusWebView loadHTMLString:[self generateStatusHTML] baseURL:nil];
}

- (void) isGoingAway {
}

- (void) showOverlay:(BOOL) forceReshow {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSBundle* locBundle = [NSBundle localisationBundle];
    BOOL workingForceReshow = forceReshow;
    
    // Update TouchId status
    [self refreshIsTouchIdAvailable];
    
    ICLTrainingOverlayData* overlay = nil;
    
    overlay = [ICLTrainingOverlayInstance registerScreen:@"ICL_SecuritySetup"
                                               titleText:NSLocalizedStringFromTableInBundle(@"Training.Title", @"ICL_Security", locBundle, @"Security Setup")
                                             description:NSLocalizedStringFromTableInBundle(@"Training.Description", @"ICL_Security", locBundle, @"From this screen you can enable, disable and change the security settings.")];
    
    [overlay addElement:securityStatusWebView description:NSLocalizedStringFromTableInBundle(@"Training.Summary", @"ICL_Security", locBundle, @"This is a summary of the current security status.")];

    // If using a small iPhone then split the training screen at this point
    if (Using_iPhone && !Using_iPhone6OrLarger) {
        overlay = [ICLTrainingOverlayInstance registerScreen:@"ICL_SecuritySetup_Part2"
                                                   titleText:@""
                                                 description:@""];
        
    }
    
    // Check if a pass code has already been set
    if ([userDefaults boolForKey:ICL_Security_AppSecuredKey]) {
        // Force a reshow if we have never shown the training for the change passcode button
        workingForceReshow |= ![userDefaults boolForKey:ICL_Security_Training_ShownChangePassCode];
        [userDefaults setBool:YES forKey:ICL_Security_Training_ShownChangePassCode];
        [userDefaults synchronize];
        
        [overlay addElement:togglePassCodeButton description:NSLocalizedStringFromTableInBundle(@"Training.DisablePassCode", @"ICL_Security", locBundle, @"Tap here to disable requiring a passcode or TouchId.")];
        
        [overlay addElement:setPassCodeButton description:NSLocalizedStringFromTableInBundle(@"Training.SetPassCode", @"ICL_Security", locBundle, @"Tap here to change the passcode.")];
        
        // Check if Touch ID is enabled
        if (touchIdAvailable) {
            // Force a reshow if we have never shown the training for the toggle TouchId button
            workingForceReshow |= ![userDefaults boolForKey:ICL_Security_Training_ShownToggleTouchId];
            [userDefaults setBool:YES forKey:ICL_Security_Training_ShownToggleTouchId];
            [userDefaults synchronize];
            
            if ([userDefaults boolForKey:ICL_Security_TouchIdEnabled]) {
                [overlay addElement:toggleTouchIdButton description:NSLocalizedStringFromTableInBundle(@"Training.DisableTouchId", @"ICL_Security", locBundle, @"Tap here to disable TouchId as an alternative to the app passcode.")];
            }
            else {
                [overlay addElement:toggleTouchIdButton description:NSLocalizedStringFromTableInBundle(@"Training.EnableTouchId", @"ICL_Security", locBundle, @"Tap here to enable TouchId as an alternative to the app passcode.")];
            }
        }
    }
    else {
        [overlay addElement:togglePassCodeButton description:NSLocalizedStringFromTableInBundle(@"Training.EnablePassCode", @"ICL_Security", locBundle, @"Tap here to require a passcode after a period of inactivity.")];
    }
    
    [ICLTrainingOverlayInstance showScreen:@"ICL_SecuritySetup" forceReshow:workingForceReshow currentViewController:self displayPosition:edpBottom];
    
    // If using a small iPhone then split the training screen at this point
    if (Using_iPhone && !Using_iPhone6OrLarger) {
        [ICLTrainingOverlayInstance showScreen:@"ICL_SecuritySetup_Part2" forceReshow:workingForceReshow currentViewController:self displayPosition:edpTop];
        
    }
}

#pragma mark Interface Handling

- (IBAction) togglePassCode:(id) sender {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults boolForKey:ICL_Security_AppSecuredKey]) {
        // Disable the PIN code and TouchId
        [userDefaults setBool:NO forKey:ICL_Security_AppSecuredKey];
        [userDefaults setBool:NO forKey:ICL_Security_TouchIdEnabled];
        [userDefaults synchronize];
        
        // Wipe the keychain
        [keychain resetKeychainItem];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refresh];
            [self showOverlay:NO];
            
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Passcode.Disabled.Title", @"ICL_Security", [NSBundle localisationBundle], @"Passcode Disabled")
                                        message:NSLocalizedStringFromTableInBundle(@"Passcode.Disabled.Message", @"ICL_Security", [NSBundle localisationBundle], @"Passcode security has been disabled for this app.")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok")
                              otherButtonTitles:nil] show];
        });
    }
    else {
        [self setPassCode:sender];
    }
}

- (IBAction) setPassCode:(id) sender {
    setupPinScreen =[[ABPadLockScreenSetupViewController alloc] initWithDelegate:self complexPin:NO];
    
    setupPinScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    setupPinScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    // Update the appearance for the lock screen
    [[ABPadLockScreenView appearance] setLabelColor:[UIColor blackColor]];
    [[ABPadLockScreenView appearance] setBackgroundColor:[UIColor colorWithHue:110.0f/360.0f saturation:0.25f brightness:0.85f alpha:1.0f]];
    [[ABPadButton appearance] setBorderColor:[UIColor blackColor]];
    [[ABPadButton appearance] setTextColor:[UIColor blackColor]];
    [[ABPadButton appearance] setSelectedColor:[UIColor colorWithHue:230.0f/360.0f saturation:0.25f brightness:0.85f alpha:1.0f]];
    
    [self presentViewController:setupPinScreen animated:YES completion:nil];
}

- (IBAction) toggleTouchId:(id) sender {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    // TouchId enabled
    if ([userDefaults boolForKey:ICL_Security_TouchIdEnabled]) {
        // Disable TouchId
        [userDefaults setBool:NO forKey:ICL_Security_TouchIdEnabled];
        [userDefaults synchronize];
        
        [self refresh];
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"TouchId.Disabled.Title", @"ICL_Security", [NSBundle localisationBundle], @"TouchID Disabled")
                                   message:NSLocalizedStringFromTableInBundle(@"TouchId.Disabled.Message", @"ICL_Security", [NSBundle localisationBundle], @"TouchID security has been disabled for this app.")
                                  delegate:nil
                         cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok")
                         otherButtonTitles:nil] show];
    } // TouchID disabled
    else {
        LAContext *context = [[LAContext alloc] init];
        
        void (^authenticationBlock_Error)(NSString*) = ^(NSString* message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"TouchId.EnableFailed.Title", @"ICL_Security", [NSBundle localisationBundle], @"Failed to Enable TouchID")
                                            message:message
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok")
                                  otherButtonTitles:nil] show];
            });
        };
        
        void (^authenticationBlock_Failed)(NSString*) = ^(NSString* message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"TouchId.EnableFailed.Title", @"ICL_Security", [NSBundle localisationBundle], @"Failed to Enable TouchID")
                                            message:NSLocalizedStringFromTableInBundle(@"TouchId.EnableFailed.Message", @"ICL_Security", [NSBundle localisationBundle], @"TouchId could not be enabled at this time. Check that TouchId has been correctly enabled on your device and try again.")
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok")
                                  otherButtonTitles:nil] show];
            });
        };
        
        // Successful authentication updates the security check and removes the security image
        void (^authenticationBlock_Successful)(NSString*) = ^(NSString* message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [userDefaults setBool:YES forKey:ICL_Security_TouchIdEnabled];
                [userDefaults synchronize];
                
                [self refresh];
                
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"TouchId.Enabled.Title", @"ICL_Security", [NSBundle localisationBundle], @"TouchID Enabled")
                                            message:NSLocalizedStringFromTableInBundle(@"TouchId.Enabled.Message", @"ICL_Security", [NSBundle localisationBundle], @"TouchID security has been enabled for this app.")
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok")
                                  otherButtonTitles:nil] show];
            });
        };
        
        // Attempt to authenticate at least once with TouchId
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:NSLocalizedStringFromTableInBundle(@"TouchIdSetup", @"ICL_Security", [NSBundle localisationBundle], @"Please verify your identity to enable TouchId")
                          reply:^(BOOL success, NSError *error) {
                              // Something went wrong with authentication
                              if (error) {
                                  if ((error.code != kLAErrorUserFallback) && (error.code != kLAErrorUserCancel)) {
                                      authenticationBlock_Error(error.localizedDescription);
                                  }
                              } // Successfully authenticated
                              else if (success) {
                                  authenticationBlock_Successful(nil);
                              } // Authentication failed
                              else {
                                  authenticationBlock_Failed(nil);
                              }
                          }];
    }
}

#pragma mark ABPadLockScreenSetupViewControllerDelegate support

- (void)pinSet:(NSString *)pin padLockScreenSetupViewController:(ABPadLockScreenSetupViewController *)padLockScreenViewController {
    [padLockScreenViewController dismissViewControllerAnimated:YES completion:^{
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Screen that just finished was the setup PIN screen
        if (padLockScreenViewController == setupPinScreen) {
            setupPinScreen = nil;
            
            // Update the keychain data
            [keychain setObject:@"" forKey:(__bridge id)kSecAttrAccount];
            [keychain setObject:pin forKey:(__bridge id)kSecValueData];

            // Enable the PIN code
            [userDefaults setBool:YES forKey:ICL_Security_AppSecuredKey];
            [userDefaults setInteger:15 forKey:ICL_Security_TimeBetweenChecks];
            [userDefaults synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refresh];
                [self showOverlay:NO];
            });
        }
    }];
}

#pragma mark ABPadLockScreenDelegate support

- (void)unlockWasCancelledForPadLockScreenViewController:(ABPadLockScreenAbstractViewController *)padLockScreenViewController {
    [padLockScreenViewController dismissViewControllerAnimated:YES completion:^{
        // Screen that just finished was the setup PIN screen
        if (padLockScreenViewController == setupPinScreen) {
            setupPinScreen = nil;
        }
    }];
}

#pragma mark Interface Generation

- (NSString*) generateStatusHTML {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableString* html = [[NSMutableString alloc] init];
    
    [html appendString:@"<!DOCTYPE html>"];
    [html appendString:@"<html>"];
    
    [html appendString:@"    <head>"];
    [html appendString:@"        <style type=\"text/css\">"];
    [html appendString:@"            body { font-family: \"HelveticaNeue-Thin\", \"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", \"Helvetica\", \"Arial\", \"Lucida Grande\", \"sans-serif\"; background-color: transparent; color: black; margin: 0; padding: 0; }"];
    [html appendString:@"            table { border: 0px solid black; }"];
    [html appendString:@"        </style>"];
    [html appendString:@"    </head>"];
    
    [html appendString:@"    <body>"];
    
    NSString* baseSecurityLevelString = NSLocalizedStringFromTableInBundle(@"Setup.SecurityLevelSummary", @"ICL_Security", [NSBundle localisationBundle], @"Current security level is %@");
    NSString* securityLevelString = nil;

    // Generate the security level string
    if (securityLevel == eslLow) {
        NSString* levelString = [NSString stringWithFormat:@"<span style=\"color: %@\">%@</span>", [[UIColor redColor] htmlHexString], NSLocalizedStringFromTableInBundle(@"SecurityLevel.Low", @"ICL_Security", [NSBundle localisationBundle], @"Low")];
        
        securityLevelString = [NSString stringWithFormat:baseSecurityLevelString, levelString];
    }
    else if (securityLevel == eslMedium) {
        NSString* levelString = [NSString stringWithFormat:@"<span style=\"color: %@\">%@</span>", [[UIColor redColor] htmlHexString], NSLocalizedStringFromTableInBundle(@"SecurityLevel.Medium", @"ICL_Security", [NSBundle localisationBundle], @"Medium")];
        
        securityLevelString = [NSString stringWithFormat:baseSecurityLevelString, levelString];
    }
    else {
        NSString* levelString = [NSString stringWithFormat:@"<span style=\"color: %@\">%@</span>", [[UIColor redColor] htmlHexString], NSLocalizedStringFromTableInBundle(@"SecurityLevel.High", @"ICL_Security", [NSBundle localisationBundle], @"High")];
        
        securityLevelString = [NSString stringWithFormat:baseSecurityLevelString, levelString];
    }
    
    NSString* summary_BlurringOn = NSLocalizedStringFromTableInBundle(@"Summary.Blurring.On", @"ICL_Security", [NSBundle localisationBundle], @"The screen will be blurred when you leave the app.");
    
    NSString* summary_PassCodeOff = NSLocalizedStringFromTableInBundle(@"Summary.PassCode.Off", @"ICL_Security", [NSBundle localisationBundle], @"No passcode has been set.");
    NSString* summary_PassCodeOn = NSLocalizedStringFromTableInBundle(@"Summary.PassCode.On", @"ICL_Security", [NSBundle localisationBundle], @"A passcode is required after a period of inactivity.");

    NSString* summary_TouchIdNotSupported = NSLocalizedStringFromTableInBundle(@"Summary.TouchId.NotSupported", @"ICL_Security", [NSBundle localisationBundle], @"TouchId is not available.");
    NSString* summary_TouchIdOff = NSLocalizedStringFromTableInBundle(@"Summary.TouchId.Off", @"ICL_Security", [NSBundle localisationBundle], @"TouchId is available but not enabled.");
    NSString* summary_TouchIdOn = NSLocalizedStringFromTableInBundle(@"Summary.TouchId.On", @"ICL_Security", [NSBundle localisationBundle], @"TouchId is required after a period of inactivity.");

    [html appendFormat:@"        %@", securityLevelString];
    
    [html appendString:@"        <table width=\"100%\">"];
    
    [html appendFormat:@"        <tr><td>\U00002B06</td><td>%@</td></tr>", summary_BlurringOn];

    if ([userDefaults boolForKey:ICL_Security_AppSecuredKey]) {
        [html appendFormat:@"        <tr><td>\U00002B06</td><td>%@</td></tr>", summary_PassCodeOn];
        
        if ([userDefaults boolForKey:ICL_Security_TouchIdEnabled]) {
            [html appendFormat:@"        <tr><td>\U00002B06</td><td>%@</td></tr>", summary_TouchIdOn];
        }
        else if (touchIdAvailable) {
            [html appendFormat:@"        <tr><td>\U00002B07</td><td>%@</td></tr>", summary_TouchIdOff];
        }
        else {
            [html appendFormat:@"        <tr><td>\U00002B07</td><td>%@</td></tr>", summary_TouchIdNotSupported];
        }
    }
    else {
        [html appendFormat:@"        <tr><td>\U00002B07</td><td>%@</td></tr>", summary_PassCodeOff];
        
        if (touchIdAvailable) {
            [html appendFormat:@"        <tr><td>\U00002B07</td><td>%@</td></tr>", summary_TouchIdOff];
        }
        else {
            [html appendFormat:@"        <tr><td>\U00002B07</td><td>%@</td></tr>", summary_TouchIdNotSupported];
        }
    }
    
    [html appendString:@"        </table>"];
    
    [html appendString:@"    </body>"];
    [html appendString:@"</html>"];
    
   
    return html;
}

- (void) createInterface {
    // Create the webview
    securityStatusWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [securityStatusWebView setBackgroundColor:[UIColor clearColor]];
    [securityStatusWebView setOpaque:NO];
    [securityStatusWebView setUserInteractionEnabled:NO];
    [securityStatusWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:securityStatusWebView];
    
    // Setup the webview constraints
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-10-[webView]-10-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:@{@"webView" : securityStatusWebView}]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-20-[webView(==160)]"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:@{@"webView" : securityStatusWebView}]];
    
    NSDictionary* fontAttributes = @{@"NSCTFontUIUsageAttribute" : UIFontTextStyleBody,
                                     @"NSFontNameAttribute" : @"HelveticaNeue-Light"};
    UIFont* font = [UIFont fontWithDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:fontAttributes]
                                         size:18.0];
    
    // Create the toggle pass code button
    togglePassCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [togglePassCodeButton setBackgroundColor:defaultButtonColour];
    [togglePassCodeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [togglePassCodeButton.titleLabel setFont:font];
    [togglePassCodeButton addTarget:self action:@selector(togglePassCode:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:togglePassCodeButton];
    
    // Create the set pass code button
    setPassCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [setPassCodeButton setBackgroundColor:defaultButtonColour];
    [setPassCodeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [setPassCodeButton.titleLabel setFont:font];
    [setPassCodeButton addTarget:self action:@selector(setPassCode:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setPassCodeButton];
    
    // Create the toggle touch Id button
    toggleTouchIdButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [toggleTouchIdButton setBackgroundColor:defaultButtonColour];
    [toggleTouchIdButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [toggleTouchIdButton.titleLabel setFont:font];
    [toggleTouchIdButton addTarget:self action:@selector(toggleTouchId:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggleTouchIdButton];
    
    // Using the iPad
    if (Using_iPad) {
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-20-[togglePassCodeButton(==touchIdButton)]-20-[passCodeButton(==touchIdButton)]-20-[touchIdButton]-20-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"togglePassCodeButton" : togglePassCodeButton,
                                           @"passCodeButton" : setPassCodeButton,
                                           @"touchIdButton" : toggleTouchIdButton}]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[webView]-10-[togglePassCodeButton(==30)]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"webView" : securityStatusWebView,
                                           @"togglePassCodeButton" : togglePassCodeButton}]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[webView]-10-[passCodeButton(==30)]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"webView" : securityStatusWebView,
                                           @"passCodeButton" : setPassCodeButton}]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[webView]-10-[touchIdButton(==30)]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"webView" : securityStatusWebView,
                                           @"touchIdButton" : toggleTouchIdButton}]];
    } // Using iPhone
    else {
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-20-[passCodeButton]-20-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"passCodeButton" : setPassCodeButton}]];
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-20-[touchIdButton]-20-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"touchIdButton" : toggleTouchIdButton}]];
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-20-[togglePassCodeButton]-20-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"togglePassCodeButton" : togglePassCodeButton}]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[webView]-10-[togglePassCodeButton(==30)]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"webView" : securityStatusWebView,
                                           @"togglePassCodeButton" : togglePassCodeButton}]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[togglePassCodeButton]-10-[passCodeButton(==30)]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"togglePassCodeButton" : togglePassCodeButton,
                                           @"passCodeButton" : setPassCodeButton}]];
        
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[passCodeButton]-10-[touchIdButton(==30)]"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:@{@"passCodeButton" : setPassCodeButton,
                                           @"touchIdButton" : toggleTouchIdButton}]];
    }
}

@end
