//
//  ICLTrainingOverlayCommon.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 8/09/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#ifndef iOSCoreLibrary_ICLTrainingOverlayCommon_h
#define iOSCoreLibrary_ICLTrainingOverlayCommon_h

typedef enum {
    etsDarken,
    etsGlass
} TrainingOverlayStyle;

typedef enum {
    edpNone,
    
    edpLeft,
    edpLeft_Quarter,
    edpLeft_Third,
    edpLeft_TwoThirds,
    edpLeft_ThreeQuarters,
    
    edpRight,
    edpRight_Quarter,
    edpRight_Third,
    edpRight_TwoThirds,
    edpRight_ThreeQuarters,
    
    edpTop,
    edpTop_Quarter,
    edpTop_Third,
    edpTop_TwoThirds,
    edpTop_ThreeQuarters,
    
    edpBottom,
    edpBottom_Quarter,
    edpBottom_Third,
    edpBottom_TwoThirds,
    edpBottom_ThreeQuarters
} DisplayPosition;

extern NSString* const kICLTrainingOverlayCSSName;
extern NSString* const kICLTrainingOverlayBaseURL;

extern float const kICLHighlightRectSizeAdjustment;

#endif
