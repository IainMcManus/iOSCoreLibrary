//
//  ICLSecureAppDelegate.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 29/04/2015.
//  Copyright (c) 2015 Iain McManus. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface ICLSecureAppDelegate : UIResponder<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void) appBecameLocked;
- (void) appBecameUnlocked;

@end

#endif // TARGET_OS_IPHONE