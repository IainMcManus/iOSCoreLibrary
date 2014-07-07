//
//  NSBundle+InternalExtensions.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 2/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "NSBundle+InternalExtensions.h"

@implementation NSBundle (InternalExtensions)

+ (NSBundle*) localisationBundle {
    static NSBundle* locBundle = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        NSString* libraryBundlePath = [[NSBundle mainBundle] pathForResource:@"iOSCoreLibraryBundle" ofType:@"bundle"];
        NSBundle* libraryBundle = [NSBundle bundleWithPath:libraryBundlePath];
        
        for (NSString* languageId in [NSLocale preferredLanguages]) {
            NSString* path = [libraryBundle pathForResource:languageId ofType:@"lproj"];
            if (path) {
                locBundle = [NSBundle bundleWithPath:path];
                break;
            }
        }
    });
    
    return locBundle;
}

@end
