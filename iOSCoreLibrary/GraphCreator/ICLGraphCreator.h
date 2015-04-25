//
//  ICLGraphCreator.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 19/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    iclgtPieChart,
    iclgtHollowPieChart,
    iclgtBarGraph,
    iclgtLineGraph,
    iclgtStackedBarGraph
} ICLGraphType;

@class UIImage;

extern NSString* kICLWidthKey;
extern NSString* kICLHeightKey;
extern NSString* kICLDataColours;
extern NSString* kICLMaximumColour;
extern NSString* kICLFontSize;
extern NSString* kICLFontSize_LegendLabel;
extern NSString* kICLNumLabelsAcrossForLegend;
extern NSString* kICLCategoryColours;
extern NSString* kICLCategoryOrders;

extern NSString* kICLMarginLeft;
extern NSString* kICLMarginRight;
extern NSString* kICLMarginTop;
extern NSString* kICLMarginBottom;
extern NSString* kICLLegendHeight;

extern NSString* kICLAxisWidth;

extern NSString* kICLValueLabels;
extern NSString* kICLXAxisLabels;
extern NSString* kICLYAxisLabels;

extern NSString* kICLMaximumValue;

@interface ICLGraphCreator : NSObject

+ (UIImage*) createGraph:(ICLGraphType) type
                  labels:(NSDictionary*) labels
                  values:(NSArray*) values
            valueStrings:(NSArray*) valueStrings
              attributes:(NSDictionary*) attributes
     showLegendForHidden:(BOOL) showLegendForHidden;

@end
