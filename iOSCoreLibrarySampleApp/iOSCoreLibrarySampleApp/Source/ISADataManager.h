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

typedef enum {
    emtPet              = 0x01,
    emtOwner            = 0x02,
    emtClassification   = 0x04
} ModelType;

typedef enum {
    ectAdd      = 0x01,
    ectUpdate   = 0x02,
    ectDelete   = 0x04
} ChangeType;

@class Pet;
@class Owner;
@class Classification;

@interface ISADataManager : NSObject

- (void) applicationInitialised;
+ (ISADataManager*) Instance;

- (UIViewController*) currentViewController;

- (void) registerStoreChangedDelegate:(id) inHandler;
- (void) unregisterStoreChangedDelegate:(id) inHandler;

- (void) registerPetChangedDelegate:(id) inHandler;
- (void) unregisterPetChangedDelegate:(id) inHandler;

- (void) registerOwnerChangedDelegate:(id) inHandler;
- (void) unregisterOwnerChangedDelegate:(id) inHandler;

- (void) registerClassificationChangedDelegate:(id) inHandler;
- (void) unregisterClassificationChangedDelegate:(id) inHandler;

- (void) registerDataChangedDelegate:(id) inHandler;
- (void) unregisterDataChangedDelegate:(id) inHandler;

@end

@protocol StoreChangedDelegate <NSObject>

- (void) storeWillChange;
- (void) storeDidChange;

@end;

@protocol PetChangedDelegate <NSObject>

- (void) petDeleted:(Pet*) pet remoteChange:(BOOL) isRemoteChange;
- (void) petAdded:(Pet*) pet remoteChange:(BOOL) isRemoteChange;
- (void) petUpdated:(Pet*) pet remoteChange:(BOOL) isRemoteChange;

@end;

@protocol OwnerChangedDelegate <NSObject>

- (void) ownerDeleted:(Owner*) owner remoteChange:(BOOL) isRemoteChange;
- (void) ownerAdded:(Owner*) owner remoteChange:(BOOL) isRemoteChange;
- (void) ownerUpdated:(Owner*) owner remoteChange:(BOOL) isRemoteChange;

@end;

@protocol ClassificationChangedDelegate <NSObject>

- (void) classificationDeleted:(Classification*) classification remoteChange:(BOOL) isRemoteChange;
- (void) classificationAdded:(Classification*) classification remoteChange:(BOOL) isRemoteChange;
- (void) classificationUpdated:(Classification*) classification remoteChange:(BOOL) isRemoteChange;

@end;

@protocol DataChangedDelegate <NSObject>

- (void) dataChanged:(NSDictionary*) changeInfo remoteChange:(BOOL) isRemoteChange;

@end;
