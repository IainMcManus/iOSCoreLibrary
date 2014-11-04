//
//  ICLTrainingOverlay.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 4/09/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLTrainingOverlay.h"
#import "ICLTrainingOverlayData.h"

#import <UIKit/UIKit.h>

#import "UIColor+extensions.h"
#import "UIImageEffects.h"
#import "NSBundle+InternalExtensions.h"
#import "UIViewController+Extensions.h"

NSString* const kICLTrainingOverlayCSSName = @"ICLTrainingOverlay.CSSName";
NSString* const kICLTrainingOverlayBaseURL = @"ICLTrainingOverlay.BaseURL";
NSString* const kICLTrainingOverlay_Screen = @"Screen";
NSString* const kICLTrainingOverlay_CurrentViewController = @"CurrentViewController";
NSString* const kICLTrainingOverlay_WebViewRect = @"WebViewRect";
NSString* const kICLTrainingOverlay_DisplayPosition = @"DisplayPosition";

NSString* const kICLOverlayKeyBase = @"ICLTrainingOverlay.Shown";

@interface ICLTrainingOverlay()

- (id)initInstance;

@end

@implementation ICLTrainingOverlay {
    TrainingOverlayStyle overlayStyle;
    NSString* CSSName;
    NSURL* baseURL;
    
    NSMutableDictionary* registeredScreens;
    BOOL ignorePreviouslyShownChecks;
    
    ICLTrainingOverlayData* activeOverlay;
    NSMutableArray* queuedOverlays;
    UIImage* cachedBlurredBackground;
}

#pragma mark Singleton Management

- (id) initInstance {
    if ((self = [super init])) {
        registeredScreens = [[NSMutableDictionary alloc] init];
        
        overlayStyle = etsGlass;
        activeOverlay = nil;
        queuedOverlays = [[NSMutableArray alloc] init];
        
        CSSName = @"ICLTrainingOverlay.css";
        
        cachedBlurredBackground = nil;
    }
    
    return self;
}

+ (ICLTrainingOverlay*) Instance {
    static ICLTrainingOverlay* _instance = nil;
    
    // already initialised so we can exit
    if (_instance != nil) {
        return _instance;
    }
    
    // allocate with the GCD - thread safe
    static dispatch_once_t dispatch;
    dispatch_once(&dispatch, ^(void) {
        _instance = [[ICLTrainingOverlay alloc] initInstance];
    });
    
    return _instance;
}

#pragma mark Debug Helpers

- (void) debug_IgnorePreviouslyShownChecks:(BOOL) shouldIgnore {
    ignorePreviouslyShownChecks = shouldIgnore;
}

- (void) debug_ClearPreviouslyShownFlags {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    NSDictionary* defaultsAsDictionary = [userDefaults dictionaryRepresentation];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", kICLOverlayKeyBase];
    
    NSArray* overlayKeys = [[defaultsAsDictionary allKeys] filteredArrayUsingPredicate:predicate];

    // Delete the overlay key
    for (NSString* overlayKey in overlayKeys) {
        [userDefaults removeObjectForKey:overlayKey];
    }
    
    [userDefaults synchronize];
}

#pragma mark Setting Configuration

- (void) setOverlayStyle:(TrainingOverlayStyle) newOverlayStyle {
    overlayStyle = newOverlayStyle;
}

- (void) setCSSName:(NSString*) newCSSName {
    CSSName = newCSSName;
}

- (void) setBaseURL:(NSURL*) newBaseURL {
    baseURL = newBaseURL;
}

#pragma mark Screen Setup

- (ICLTrainingOverlayData*) registerScreen:(NSString*) screen titleText:(NSString*) titleText description:(NSString*) descriptionText {
    // Don't allow double registrations of the same screen
    if (registeredScreens[screen]) {
        if (activeOverlay == registeredScreens[screen]) {
            NSLog(@"Attempting to register a screen while it is still active.");
        }
        
        [registeredScreens[screen] removeAllElements];
        
        return registeredScreens[screen];
    }
    
    registeredScreens[screen] = [[ICLTrainingOverlayData alloc] init];
    
    ICLTrainingOverlayData* overlay = registeredScreens[screen];
    overlay.screenShownKey = [NSString stringWithFormat:@"%@.%@", kICLOverlayKeyBase, screen];
    overlay.titleText = titleText;
    overlay.descriptionText = descriptionText;
    
    return overlay;
}

- (BOOL) isScreenRegistered:(NSString*) screen {
    return registeredScreens[screen] != nil;
}

#pragma mark Screen Dismissal Handling

- (void) handleTap:(UIGestureRecognizer*) recogniser {
    UIView* view = recogniser.view;
    
    // Find the overlay for the view
    ICLTrainingOverlayData* overlay = nil;
    for (ICLTrainingOverlayData* overlayData in [registeredScreens allValues]) {
        if (overlayData.overlayView == view) {
            overlay = overlayData;
            
            break;
        }
    }
    
    // Overlay not found? should never happen
    if (!overlay) {
        NSLog(@"The overlay could not be found and will not be closed.");
        assert(0);
        
        return;
    }
    
    // Remove the gesture recogniser from the view
    [overlay.overlayView removeGestureRecognizer:recogniser];
    
    // Remove the overlay and clear the data
    [overlay.overlayView removeFromSuperview];
    overlay.overlayView = nil;
    
    activeOverlay = nil;
    
    if (![self resumeShowingOverlays]) {
        cachedBlurredBackground = nil;
        
        [self.delegate currentOverlaySequenceComplete];
    }
}

#pragma mark Screen Display

- (BOOL) resumeShowingOverlays {
    if (!activeOverlay && ([queuedOverlays count] > 0)) {
        NSDictionary* showScreenRequest = [queuedOverlays firstObject];
        [queuedOverlays removeObjectAtIndex:0];

        ICLTrainingOverlayData* overlayData = registeredScreens[showScreenRequest[kICLTrainingOverlay_Screen]];

        [self showScreen_Internal:overlayData
            currentViewController:showScreenRequest[kICLTrainingOverlay_CurrentViewController]
                      webViewRect:showScreenRequest[kICLTrainingOverlay_WebViewRect]
                  displayPosition:(DisplayPosition)[showScreenRequest[kICLTrainingOverlay_DisplayPosition] integerValue]];
        
        return YES;
    }
    
    return NO;
}

- (BOOL) showScreen:(NSString*) screen forceReshow:(BOOL) forceReshow currentViewController:(UIViewController*) currentVC displayPosition:(DisplayPosition) displayPosition {
    return [self showScreen_Wrapper:screen forceReshow:forceReshow currentViewController:currentVC webViewRect:nil displayPosition:displayPosition];
}

- (BOOL) showScreen:(NSString*) screen forceReshow:(BOOL) forceReshow currentViewController:(UIViewController*) currentVC webViewRect:(NSValue*) webViewRect {
    return [self showScreen_Wrapper:screen forceReshow:forceReshow currentViewController:currentVC webViewRect:webViewRect displayPosition:edpNone];
}

- (BOOL) showScreen_Wrapper:(NSString*) screen
                forceReshow:(BOOL) forceReshow
      currentViewController:(UIViewController*) currentVC
                webViewRect:(NSValue*) webViewRect
            displayPosition:(DisplayPosition) displayPosition {
    ICLTrainingOverlayData* overlayData = registeredScreens[screen];
    
    // Can't show if the overlay does not exist
    if (!overlayData) {
        NSLog(@"Screen has never been registered!");
        assert(0);
        
        return NO;
    }
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Don't show if the user defaults say we have already been shown
    if (!ignorePreviouslyShownChecks && !forceReshow && [userDefaults boolForKey:overlayData.screenShownKey]) {
        return NO;
    }
    
    // If we already have an active overlay then add the requested one to the queue
    // OR, if we have a delegate and we are not yet ready to show an overlay
    if (activeOverlay || ([queuedOverlays count] > 0) || (self.delegate && ![self.delegate readyToShowOverlays])) {
        // Check if the overlay has already been queued
        BOOL alreadyExists = NO;
        for (NSDictionary* queuedOverlay in queuedOverlays) {
            if ([queuedOverlay[kICLTrainingOverlay_Screen] isEqualToString:screen]) {
                alreadyExists = YES;
                break;
            }
        }
        
        if (!alreadyExists) {
            [queuedOverlays addObject:@{kICLTrainingOverlay_Screen: screen,
                                        kICLTrainingOverlay_CurrentViewController: currentVC,
                                        kICLTrainingOverlay_WebViewRect: webViewRect ? webViewRect : [NSNull null],
                                        kICLTrainingOverlay_DisplayPosition: @(displayPosition)}];
        }
    } // Otherwise show the overlay immediately
    else {
        activeOverlay = overlayData;
        
        // Show the screen
        [self showScreen_Internal:overlayData currentViewController:currentVC webViewRect:webViewRect displayPosition:displayPosition];
    }
    
    return YES;
}

- (CGRect) calculateWebViewRect:(CGRect) overlayBounds displayPosition:(DisplayPosition) displayPosition {
    CGRect webViewRect;
    
    if (displayPosition == edpLeft) {
        webViewRect = CGRectMake(0,
                                 0,
                                 overlayBounds.size.width * 0.5f,
                                 overlayBounds.size.height);
    }
    else if (displayPosition == edpLeft_TwoThirds) {
        webViewRect = CGRectMake(0,
                                 0,
                                 overlayBounds.size.width * 0.66f,
                                 overlayBounds.size.height);
    }
    else if (displayPosition == edpLeft_ThreeQuarters) {
        webViewRect = CGRectMake(0,
                                 0,
                                 overlayBounds.size.width * 0.75f,
                                 overlayBounds.size.height);
    }
    else if (displayPosition == edpRight) {
        webViewRect = CGRectMake(overlayBounds.size.width * 0.5f,
                                 0,
                                 overlayBounds.size.width * 0.5f,
                                 overlayBounds.size.height);
    }
    else if (displayPosition == edpRight_TwoThirds) {
        webViewRect = CGRectMake(overlayBounds.size.width * 0.33f,
                                 0,
                                 overlayBounds.size.width * 0.66f,
                                 overlayBounds.size.height);
    }
    else if (displayPosition == edpRight_ThreeQuarters) {
        webViewRect = CGRectMake(overlayBounds.size.width * 0.25f,
                                 0,
                                 overlayBounds.size.width * 0.75f,
                                 overlayBounds.size.height);
    }
    else if (displayPosition == edpTop) {
        webViewRect = CGRectMake(0,
                                 0,
                                 overlayBounds.size.width,
                                 overlayBounds.size.height * 0.5f);
    }
    else if (displayPosition == edpTop_TwoThirds) {
        webViewRect = CGRectMake(0,
                                 0,
                                 overlayBounds.size.width,
                                 overlayBounds.size.height * 0.66f);
    }
    else if (displayPosition == edpTop_ThreeQuarters) {
        webViewRect = CGRectMake(0,
                                 0,
                                 overlayBounds.size.width,
                                 overlayBounds.size.height * 0.75f);
    }
    else if (displayPosition == edpBottom) {
        webViewRect = CGRectMake(0,
                                 overlayBounds.size.height * 0.5f,
                                 overlayBounds.size.width,
                                 overlayBounds.size.height * 0.5f);
    }
    else if (displayPosition == edpBottom_TwoThirds) {
        webViewRect = CGRectMake(0,
                                 overlayBounds.size.height * 0.33f,
                                 overlayBounds.size.width,
                                 overlayBounds.size.height * 0.66f);
    }
    else if (displayPosition == edpBottom_ThreeQuarters) {
        webViewRect = CGRectMake(0,
                                 overlayBounds.size.height * 0.25f,
                                 overlayBounds.size.width,
                                 overlayBounds.size.height * 0.75f);
    }
    else {
        CGFloat width;
        CGFloat height;
        
        if (overlayBounds.size.width > overlayBounds.size.height) {
            width = overlayBounds.size.width * 0.75f;
            height = overlayBounds.size.height * 0.75f;
        }
        else {
            width = overlayBounds.size.width * 1.0f;
            height = overlayBounds.size.height * 0.75f;
        }
        
        webViewRect = CGRectMake((overlayBounds.size.width - width) * 0.5f,
                                 (overlayBounds.size.height - height) * 0.5f,
                                 width,
                                 height);
    }
    
    return webViewRect;
}

- (void) showScreen_Internal:(ICLTrainingOverlayData*) overlay
       currentViewController:(UIViewController*) currentVC
                 webViewRect:(NSValue*) webViewRect
             displayPosition:(DisplayPosition) displayPosition {
    // Flag the screen as shown
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:overlay.screenShownKey];
    [userDefaults synchronize];

    // We need the true parent VC
    UIViewController* topVC = [currentVC topViewController];
    while ([topVC parentViewController] != nil) {
        topVC = [topVC parentViewController];
    }
    
    // Dismiss the keyboard
    [currentVC.view endEditing:YES];
    
    CGRect overlayBounds = topVC.view.bounds;
    
    // Instantiate the overlay view
    overlay.overlayView = [[UIView alloc] initWithFrame:overlayBounds];
    
    // If the webview bounds were not overridden then set defaults
    if (!webViewRect || [webViewRect isEqual:[NSNull null]]) {
        CGRect webViewRect = [self calculateWebViewRect:overlayBounds displayPosition:displayPosition];
        
        overlay.webViewBounds = [NSValue valueWithCGRect:webViewRect];
    }
    else {
        overlay.webViewBounds = webViewRect;
    }
    
    // Add the overlay view and bring it to the foreground
    [topVC.view addSubview:overlay.overlayView];
    
    // Setup the tap gesture so we can auto close the screen
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.cancelsTouchesInView = NO;
    [overlay.overlayView addGestureRecognizer:tapRecognizer];
    
    // Refresh the internal state for the screen
    [overlay refreshInternalData:overlayStyle];
    
    UIImage* backgroundImage = nil;

    // Generate the background image
    if (overlayStyle == etsDarken) {
        backgroundImage = [self buildScreenBackground_Darken:overlay bounds:overlayBounds];
    }
    else {
        backgroundImage = [self buildScreenBackground_Glass:overlay bounds:overlayBounds];
    }
    
    // Add the background image
    if (backgroundImage) {
        UIImageView* imageView = [[UIImageView alloc] initWithImage:backgroundImage];
        
        imageView.frame = overlayBounds;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [overlay.overlayView addSubview:imageView];
        [overlay.overlayView sendSubviewToBack:imageView];
    }
    else {
        NSLog(@"The background image failed to generate for an unknown reason");
    }
    
    // Generate the highlights image
    UIImage* highlightsImage = [self buildScreenHighlights:overlay bounds:overlayBounds];
    
    // Add the highlights image
    if (highlightsImage) {
        UIImageView* imageView = [[UIImageView alloc] initWithImage:highlightsImage];
        
        imageView.frame = overlayBounds;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [overlay.overlayView addSubview:imageView];
    }
    else {
        NSLog(@"The highlights image failed to generate for an unknown reason");
    }
    
    // Generate the overlay html
    NSString* overlayHTML = [self buildOverlayHTML:overlay];
    
    // Add the webview for the overlay html
    UIWebView* webView = [[UIWebView alloc] initWithFrame:[overlay.webViewBounds CGRectValue]];
    [webView setBackgroundColor:[UIColor clearColor]];
    [webView setOpaque:NO];
    [webView loadHTMLString:overlayHTML baseURL:baseURL];
    [webView setUserInteractionEnabled:NO];
    [overlay.overlayView addSubview:webView];
}

#pragma mark HTML Overlay Generation

- (NSString*) buildOverlayHTML:(ICLTrainingOverlayData*) overlay {
    NSMutableString* html = [[NSMutableString alloc] init];
    
    [html appendString:@"<!DOCTYPE html>"];
    [html appendString:@"<html>"];

    [html appendString:@"    <head>"];
    [html appendFormat:@"        <link rel=\"stylesheet\" type=\"text/css\" href=\"%@\"/>", CSSName];
    [html appendString:@"    </head>"];
    
    [html appendString:@"    <body>"];
    
    [html appendString:@"        <div class=\"TrainingOverlay\">"];
    [html appendFormat:@"            <h1 class=\"OverlayTitle\">%@</h1>", overlay.titleText];
    [html appendFormat:@"            <p class=\"OverlayDescription\">%@</p>", overlay.descriptionText];
    
    [html appendString:@"            <div class=\"ElementList\">"];

    for (NSUInteger elementIndex = 0; elementIndex < [overlay numElements]; ++elementIndex) {
        UIColor* elementColour = [overlay colourForElement:elementIndex];
        NSString* elementDescription = [overlay descriptionForElement:elementIndex];
        
        [html appendString:@"                <p class=\"Element\">"];
        [html appendFormat:@"                    <span class=\"ElementBullet\" style=\"color: %@\">&#x25B6;</span>", [elementColour htmlHexString]];
        [html appendFormat:@"                    <span class=\"ElementDescription\">%@</span>", elementDescription];
        [html appendString:@"                </p>"];
    }
    
    [html appendString:@"            </div>"];
    
    NSString* tapToClose = NSLocalizedStringFromTableInBundle(@"Overlay.TapToClose", @"ICL_TrainingOverlay", [NSBundle localisationBundle], @"[Tap anywhere to close]");
    [html appendFormat:@"            <h2 class=\"OverlayTapToClose\">%@</h2>", tapToClose];
    
    [html appendString:@"        </div>"];
    [html appendString:@"    </body>"];
    [html appendString:@"</html>"];

    return html;
}

#pragma mark Element Highlight Generation

- (UIImage*) buildScreenHighlights:(ICLTrainingOverlayData*) overlay bounds:(CGRect) overlayBounds {
    UIImage* image = nil;
    
    @autoreleasepool {
        // Setup our graphics context
        UIGraphicsBeginImageContextWithOptions(overlayBounds.size, NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        // Iterate over all of the elements drawing the background data
        for (NSUInteger elementIndex = 0; elementIndex < [overlay numElements]; ++elementIndex) {
            CGRect elementRect = [overlay rectForElement:elementIndex];
            UIColor* elementColour = [overlay colourForElement:elementIndex];
            
            CGContextSaveGState(context);

            [self addElementToHighlights:context elementRect:elementRect colour:elementColour bounds:overlayBounds];
            
            CGContextFlush(context);
            
            CGContextRestoreGState(context);
        }
        
        // Flush the context and clear any state changes
        CGContextFlush(context);
        UIGraphicsPopContext();
        
        // Retrieve the generated image
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        // Cleanup the context
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (void) addElementToHighlights:(CGContextRef) context
                    elementRect:(CGRect) elementRect
                         colour:(UIColor*) colour
                         bounds:(CGRect) overlayBounds {
    CGFloat cornerRadius = MIN(MIN(elementRect.size.width, elementRect.size.height) * 0.25f, 10);
    CGFloat buffer = 3.0f;
    
    CGRect workingRect = CGRectMake(elementRect.origin.x - buffer * 0.5f,
                                    elementRect.origin.y - buffer * 0.5f,
                                    elementRect.size.width + buffer,
                                    elementRect.size.height + buffer);
    
    CGRect intersectedRect = CGRectIntersection(workingRect, overlayBounds);
    
    if (!CGRectIsNull(intersectedRect)) {
        workingRect = intersectedRect;
    }
    
    UIBezierPath* bezeirPath = [UIBezierPath bezierPathWithRoundedRect:workingRect cornerRadius:cornerRadius];
    
    CGContextSetStrokeColorWithColor(context, colour.CGColor);
    [bezeirPath setLineWidth:2.0f];
    [bezeirPath stroke];
}

#pragma mark Background Generation - Glass

- (UIImage*) buildScreenBackground_Glass:(ICLTrainingOverlayData*) overlay bounds:(CGRect) overlayBounds {
    UIImage* image = nil;

    @autoreleasepool {
        if (!cachedBlurredBackground) {
            // Setup our graphics context
            UIGraphicsBeginImageContextWithOptions(overlayBounds.size, NO, 1.0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            UIGraphicsPushContext(context);
            
            // Capture the screen
            UIView* superView = [overlay.overlayView superview];
            [superView drawViewHierarchyInRect:overlayBounds afterScreenUpdates:YES];
            
            // Flush the context and clear any state changes
            CGContextFlush(context);
            UIGraphicsPopContext();
            
            // Retrieve the generated image
            image = UIGraphicsGetImageFromCurrentImageContext();
            
            // Cleanup the context
            UIGraphicsEndImageContext();
            
            // Blur the image
            image = [UIImageEffects imageByApplyingBlurToImage:image
                                                    withRadius:10
                                                     tintColor:[UIColor colorWithWhite:1.0 alpha:0.3]
                                         saturationDeltaFactor:1.2
                                                     maskImage:nil];
            
            cachedBlurredBackground = [image copy];
        }
        else {
            image = [cachedBlurredBackground copy];
        }
        
        // Setup our graphics context
        UIGraphicsBeginImageContextWithOptions(overlayBounds.size, NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        // Draw the blurred image
        [image drawInRect:overlayBounds];
        
        // Iterate over all of the elements drawing the background data
        for (NSUInteger elementIndex = 0; elementIndex < [overlay numElements]; ++elementIndex) {
            CGRect elementRect = [overlay rectForElement:elementIndex];
            
            CGContextSaveGState(context);
            
            [self addElementToBackground_Glass:context elementRect:elementRect bounds:overlayBounds];
            
            CGContextFlush(context);
            
            CGContextRestoreGState(context);
        }
        
        // Flush the context and clear any state changes
        CGContextFlush(context);
        UIGraphicsPopContext();
        
        // Retrieve the generated image
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        // Cleanup the context
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (void) addElementToBackground_Glass:(CGContextRef) context
                          elementRect:(CGRect) elementRect
                               bounds:(CGRect) overlayBounds {
    CGFloat cornerRadius = MIN(MIN(elementRect.size.width, elementRect.size.height) * 0.25f, 10);
    CGFloat buffer = 4.0f;
    
    CGRect workingRect = CGRectMake(elementRect.origin.x - buffer * 0.5f,
                                    elementRect.origin.y - buffer * 0.5f,
                                    elementRect.size.width + buffer,
                                    elementRect.size.height + buffer);
    CGRect intersectedRect = CGRectIntersection(workingRect, overlayBounds);
    
    if (!CGRectIsNull(intersectedRect)) {
        workingRect = intersectedRect;
    }
    
    [[UIBezierPath bezierPathWithRoundedRect:workingRect cornerRadius:cornerRadius] addClip];
    
    CGContextClearRect(context, workingRect);
}

#pragma mark Background Generation - Darkened

- (UIImage*) buildScreenBackground_Darken:(ICLTrainingOverlayData*) overlay bounds:(CGRect) overlayBounds {
    UIImage* image = nil;
    
    @autoreleasepool {
        // Setup our graphics context
        UIGraphicsBeginImageContextWithOptions(overlayBounds.size, NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        // Fill the background with black
        CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.0f alpha:0.625f].CGColor);
        CGContextFillRect(context, overlayBounds);
        
        // Iterate over all of the elements drawing the background data
        for (NSUInteger elementIndex = 0; elementIndex < [overlay numElements]; ++elementIndex) {
            CGRect elementRect = [overlay rectForElement:elementIndex];
            
            CGContextSaveGState(context);
            
            [self addElementToBackground_Darken:context elementRect:elementRect bounds:overlayBounds];
            
            CGContextFlush(context);
            
            CGContextRestoreGState(context);
        }
        
        // Flush the context and clear any state changes
        CGContextFlush(context);
        UIGraphicsPopContext();
        
        // Retrieve the generated image
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        // Cleanup the context
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (void) addElementToBackground_Darken:(CGContextRef) context
                           elementRect:(CGRect) elementRect
                                bounds:(CGRect) overlayBounds {
    CGFloat cornerRadius = MIN(MIN(elementRect.size.width, elementRect.size.height) * 0.25f, 10);
    CGRect workingRect = elementRect;
    CGRect intersectedRect = CGRectIntersection(workingRect, overlayBounds);
    
    if (!CGRectIsNull(intersectedRect)) {
        workingRect = intersectedRect;
    }
    
    [[UIBezierPath bezierPathWithRoundedRect:workingRect cornerRadius:cornerRadius] addClip];
    
    CGContextClearRect(context, elementRect);
}

@end
