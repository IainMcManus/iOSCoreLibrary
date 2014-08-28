//
//  iOSCoreLibraryCommon.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 20/07/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#ifndef iOSCoreLibrary_iOSCoreLibraryCommon_h
#define iOSCoreLibrary_iOSCoreLibraryCommon_h

    #define Using_iOS6 (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
    #define Using_iOS7OrAbove (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
    #define Using_iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    #define Using_iPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

    extern NSString* const kICLBackgroundImage;
    extern NSString* const kICLBackgroundColour;

#endif
