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
    #define Using_iOS8OrAbove (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
    #define Using_iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    #define Using_iPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

    #define Using_4InchOrHigherPhone ([[UIScreen mainScreen] bounds].size.height >= ((double)568 - DBL_EPSILON))
    #define Using_iPhone6OrLarger ([[UIScreen mainScreen] bounds].size.height >= ((double)667 - DBL_EPSILON))

    extern NSString* const kICLBackgroundImage;
    extern NSString* const kICLBackgroundColour;

#endif
