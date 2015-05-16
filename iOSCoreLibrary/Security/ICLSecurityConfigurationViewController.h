//
//  ICLSecurityConfigurationViewController.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 3/05/2015.
//  Copyright (c) 2015 Iain McManus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICLSecurityConfigurationViewController : UIViewController

- (void) linkToParent;

- (void) storeWillChange;
- (void) storeDidChange;

- (void) refresh;
- (void) isGoingAway;

- (void) showOverlay:(BOOL) forceReshow;

@end
