//
//  ICLTrainingOverlayData.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 4/09/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "ICLTrainingOverlayCommon.h"

@interface ICLTrainingOverlayData : NSObject

@property (nonatomic, strong) NSString* screenShownKey;
@property (nonatomic, strong) UIView* overlayView;
@property (nonatomic, strong) NSString* titleText;
@property (nonatomic, strong) NSString* descriptionText;
@property (nonatomic, strong) NSMutableArray* elements;

@property (nonatomic, strong) NSValue* webViewBounds;
@property (nonatomic, strong) NSMutableArray* elementsMetadata;

- (void) addElement:(NSObject*) element description:(NSString*) elementDescription;

- (void) refreshInternalData:(TrainingOverlayStyle) overlayStyle;

- (NSUInteger) numElements;
- (CGRect) rectForElement:(NSUInteger) elementIndex;
- (UIColor*) colourForElement:(NSUInteger) elementIndex;
- (NSString*) descriptionForElement:(NSUInteger) elementIndex;

@end
