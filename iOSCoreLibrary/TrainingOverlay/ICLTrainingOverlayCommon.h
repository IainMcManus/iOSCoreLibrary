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
    edpLeft_TwoThirds,
    edpLeft_ThreeQuarters,
    
    edpRight,
    edpRight_TwoThirds,
    edpRight_ThreeQuarters,
    
    edpTop,
    edpTop_TwoThirds,
    edpTop_ThreeQuarters,
    
    edpBottom,
    edpBottom_TwoThirds,
    edpBottom_ThreeQuarters
} DisplayPosition;

extern NSString* const kICLTrainingOverlayCSSName;
extern NSString* const kICLTrainingOverlayBaseURL;

#endif
