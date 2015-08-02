//
//  ICLTrainingOverlayData.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 4/09/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "ICLTrainingOverlayCommon.h"

@interface ICLTrainingOverlayData : NSObject

@property (nonatomic, strong) NSString* overlayId;
@property (nonatomic, strong) NSString* screenShownKey;
@property (nonatomic, strong) UIView* overlayView;
@property (nonatomic, strong) NSString* titleText;
@property (nonatomic, strong) NSString* descriptionText;
@property (nonatomic, strong) NSMutableArray* elements;

@property (nonatomic, strong) NSValue* webViewBounds;
@property (nonatomic, strong) NSMutableArray* elementsMetadata;

- (void) removeAllElements;

- (void) addElement:(NSObject*) element description:(NSString*) elementDescription;
- (void) addUnhighlightedElement:(NSObject*) element;

- (void) refreshInternalData:(TrainingOverlayStyle) overlayStyle;

- (NSUInteger) numElements;
- (CGRect) rectForElement:(NSUInteger) elementIndex;
- (UIColor*) colourForElement:(NSUInteger) elementIndex;
- (NSString*) descriptionForElement:(NSUInteger) elementIndex;
- (BOOL) doesElementHaveHighlight:(NSUInteger) elementIndex;

@end

#endif // TARGET_OS_IPHONE