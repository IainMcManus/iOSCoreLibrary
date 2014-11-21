//
//  ICLTrainingOverlay.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 4/09/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ICLTrainingOverlayCommon.h"

#define ICLTrainingOverlayInstance [ICLTrainingOverlay Instance]

@class ICLTrainingOverlayData;
@class UIViewController;

@protocol ICLTrainingOverlayDelegate;

@interface ICLTrainingOverlay : NSObject

@property (weak, nonatomic) id <ICLTrainingOverlayDelegate> delegate;

+ (ICLTrainingOverlay*) Instance;

- (void) debug_IgnorePreviouslyShownChecks:(BOOL) shouldIgnore;
- (void) debug_ClearPreviouslyShownFlags;

- (void) flagAsShown:(NSArray*) screenNames;
- (void) flagAsNotShown:(NSArray*) screenNames;

- (void) setOverlayStyle:(TrainingOverlayStyle) newOverlayStyle;
- (void) setCSSName:(NSString*) newCSSName;
- (void) setBaseURL:(NSURL*) newBaseURL;

- (ICLTrainingOverlayData*) registerScreen:(NSString*) screen
                                 titleText:(NSString*) titleText
                               description:(NSString*) descriptionText;
- (BOOL) isScreenRegistered:(NSString*) screen;

- (BOOL) resumeShowingOverlays;

- (BOOL) showScreen:(NSString*) screen forceReshow:(BOOL) forceReshow currentViewController:(UIViewController*) currentVC displayPosition:(DisplayPosition) displayPosition;
- (BOOL) showScreen:(NSString*) screen forceReshow:(BOOL) forceReshow currentViewController:(UIViewController*) currentVC webViewRect:(NSValue*) webViewRect;

@end

@protocol ICLTrainingOverlayDelegate <NSObject>

@required

- (void) currentOverlaySequenceComplete;
- (BOOL) readyToShowOverlays;

@end;
