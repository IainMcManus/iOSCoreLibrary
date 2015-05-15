//
//  ICLSecureAppDelegate.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 29/04/2015.
//  Copyright (c) 2015 Iain McManus. All rights reserved.
//

#import "ICLSecureAppDelegate.h"

#import "UIImageEffects.h"
#import "NSBundle+InternalExtensions.h"
#import "ICLSecurityCommon.h"
#import "UIViewController+Extensions.h"

#import "ABPadLockScreenViewController.h"
#import "ABPadLockScreenView.h"
#import "ABPadButton.h"
#import "KeychainItemWrapper.h"

#import <LocalAuthentication/LocalAuthentication.h>
#import <Security/Security.h>

const NSInteger ICL_SecurityImageTag = 0x12345678;

@interface ICLSecureAppDelegate () <ABPadLockScreenViewControllerDelegate>

@end

@implementation ICLSecureAppDelegate {
    UIImage* blurredImage;
    NSUInteger authenticationAttemptCount;
    
    KeychainItemWrapper* keychain;
    ABPadLockScreenViewController* passCodeConfirmationScreen;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    authenticationAttemptCount = 0;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Capture the screen
    blurredImage = [self captureScreen];
    
    [self setLastCheckTime];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Show the security image
    [self showSecurityImage];
    
    [self setLastCheckTime];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self checkSecurity];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self checkSecurity];
    });
}

- (void) checkSecurity {
    // Remove the security image
    [self removeSecurityImage];
    
    // If the app is secured then show a blurred image view
    if ([self isAppSecured]) {
        // Capture the screen
        blurredImage = [self captureScreen];
        
        // Show the security image
        [self showSecurityImage];
        
        // Setup the keychain
        keychain = [[KeychainItemWrapper alloc] initWithIdentifier:ICL_Security_Keychain accessGroup:nil];
        [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)(kSecAttrAccessible)];
        
        // Authenticate the user
        [self authenticate];
    }
}

- (void) showSecurityImage {
    UIImageView* imageView = [[UIImageView alloc]initWithFrame:[self.window frame]];
    
    [imageView setImage:blurredImage];
    imageView.tag = ICL_SecurityImageTag;
    imageView.userInteractionEnabled = YES;
    
    // We need the true parent VC
    UIViewController* topVC = [self.window.rootViewController topViewController];
    while ([topVC parentViewController] != nil) {
        topVC = [topVC parentViewController];
    }
    
    [topVC.view addSubview:imageView];
}

- (void) removeSecurityImage {
    dispatch_async(dispatch_get_main_queue(), ^{
        // We need the true parent VC
        UIViewController* topVC = [self.window.rootViewController topViewController];
        while ([topVC parentViewController] != nil) {
            topVC = [topVC parentViewController];
        }
        
        // Search for the security view
        for (UIView* view in [topVC.view subviews]) {
            if ([view isKindOfClass:[UIImageView class]] && (view.tag == ICL_SecurityImageTag)) {
                [view removeFromSuperview];
            }
        }
    });
}

- (UIImage*) captureScreen {
    UIImage* capturedImage = nil;
    
    @autoreleasepool {
        CGRect screenBounds = self.window.bounds;
        
        // Setup our graphics context
        UIGraphicsBeginImageContextWithOptions(screenBounds.size, NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        // Capture the screen
        [self.window drawViewHierarchyInRect:screenBounds afterScreenUpdates:NO];
        
        // Flush the context and clear any state changes
        CGContextFlush(context);
        UIGraphicsPopContext();
        
        // Retrieve the generated image
        capturedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // Cleanup the context
        UIGraphicsEndImageContext();
        
        // Blur the image
        capturedImage = [UIImageEffects imageByApplyingBlurToImage:capturedImage
                                                        withRadius:15
                                                         tintColor:[UIColor colorWithWhite:1.0 alpha:0.5]
                                             saturationDeltaFactor:1.1
                                                         maskImage:nil];
    }
    
    return capturedImage;
}

- (BOOL) isAppSecured {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Check if the app is secured
    if ([userDefaults boolForKey:ICL_Security_AppSecuredKey]) {
        NSInteger minutesBeforeRechecking = [userDefaults integerForKey:ICL_Security_TimeBetweenChecks];
        NSTimeInterval secondsBeforeRechecking = minutesBeforeRechecking * 60;
        NSDate* lastTimeChecked = [userDefaults objectForKey:ICL_Security_LastCheckTime];
        
        // We have checked within our check time
        if (lastTimeChecked && (fabs([lastTimeChecked timeIntervalSinceNow]) < secondsBeforeRechecking)) {
            return NO;
        }

        return YES;
    }

    return NO;
}

- (BOOL) isTouchIdEnabled {
    // Check if TouchId is enabled in the config before running the actual check
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:ICL_Security_TouchIdEnabled]) {
        return NO;
    }
    
    LAContext *context = [[LAContext alloc] init];
    NSError *error = nil;
    
    return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
}

- (void) setLastCheckTime {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:ICL_Security_LastCheckTime];
    [userDefaults synchronize];
}

- (void) authenticate {
    ++ authenticationAttemptCount;
    
    void (^authenticationBlock_Error)(NSString*) = ^(NSString* message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self authenticate];
        });
    };
    
    void (^authenticationBlock_Failed)(NSString*) = ^(NSString* message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self authenticate];
        });
    };

    // Successful authentication updates the security check and removes the security image
    void (^authenticationBlock_Successful)(NSString*) = ^(NSString* message) {
        [self setLastCheckTime];
        
        [self removeSecurityImage];
    };

    // Check if touch Id is enabled
    if ([self isTouchIdEnabled] && (authenticationAttemptCount < 3)) {
        [self authenticateUsingTouchId:^(BOOL success, NSError *error) {
            // Something went wrong with authentication
            if (error) {
                authenticationBlock_Error(nil);
            } // Successfully authenticated
            else if (success) {
                authenticationBlock_Successful(nil);
            } // Authentication failed
            else {
                authenticationBlock_Failed(nil);
            }
        }];
    } // Otherwise we need to authenticate using PIN code prompt
    else {
        [self authenticateUsingPassCode];
    }
}

- (void) authenticateUsingTouchId:(void(^)(BOOL success, NSError *error)) completionHandler {
    LAContext *context = [[LAContext alloc] init];

    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:NSLocalizedStringFromTableInBundle(@"AuthenticationReason", @"ICL_Security", [NSBundle localisationBundle], @"Please verify your identity")
                      reply:completionHandler];
}

- (void) authenticateUsingPassCode {
    passCodeConfirmationScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:self complexPin:NO];
    [passCodeConfirmationScreen setAllowedAttempts:3];
    
    // Update the appearance for the lock screen
    [[ABPadLockScreenView appearance] setLabelColor:[UIColor blackColor]];
    [[ABPadLockScreenView appearance] setBackgroundColor:[UIColor colorWithHue:110.0f/360.0f saturation:0.25f brightness:0.85f alpha:1.0f]];
    [[ABPadButton appearance] setBorderColor:[UIColor blackColor]];
    [[ABPadButton appearance] setTextColor:[UIColor blackColor]];
    [[ABPadButton appearance] setSelectedColor:[UIColor colorWithHue:230.0f/360.0f saturation:0.25f brightness:0.85f alpha:1.0f]];

    // Show the authentication screen
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.window.rootViewController presentViewController:passCodeConfirmationScreen animated:NO completion:nil];
    });
}

#pragma mark ABPadLockScreenViewControllerDelegate support

- (BOOL)padLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController validatePin:(NSString*)pin {
    NSString* accountPassword = [[NSString alloc] initWithData:[keychain objectForKey:(__bridge id)kSecValueData] encoding:NSUTF8StringEncoding];
    
    return [pin isEqualToString:accountPassword];
}

- (void)unlockWasSuccessfulForPadLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController {
    [padLockScreenViewController dismissViewControllerAnimated:NO completion:^{
        [self setLastCheckTime];
        
        [self removeSecurityImage];
    }];
}

- (void)unlockWasUnsuccessful:(NSString *)falsePin afterAttemptNumber:(NSInteger)attemptNumber padLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController {
    [padLockScreenViewController dismissViewControllerAnimated:NO completion:^{
        [self authenticate];
    }];
}

- (void)unlockWasCancelledForPadLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController {
    [padLockScreenViewController dismissViewControllerAnimated:NO completion:^{
        [self authenticate];
    }];
}

@end
