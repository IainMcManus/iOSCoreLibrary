//
//  ISADataManager.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 11/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* Setting_iCloudEnabledChanged;
extern NSString* Setting_NewiCloudEnabled;

extern NSString* Notification_LoadedNewVC;

extern UIColor* Colour_AlertView_Button1;
extern UIColor* Colour_AlertView_Button2;
extern UIColor* Colour_AlertView_Panel1;
extern UIColor* Colour_AlertView_Panel2;

@interface ISADataManager : NSObject

@property (nonatomic, strong) NSMutableArray* StoreChangedDelegates;

- (void) applicationInitialised;
+ (ISADataManager*) Instance;

- (UIViewController*) currentViewController;

- (void) registerStoreChangedDelegate:(id) inHandler;
- (void) unregisterStoreChangedDelegate:(id) inHandler;

@end

@protocol StoreChangedDelegate <NSObject>

- (void) storeWillChange;
- (void) storeDidChange;

@end;
