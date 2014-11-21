//
//  ICLCoreDataManager.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 2/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ICLAlertViewController.h"

typedef enum {
    essUninitialised,
    essConvertingLegacyDataToCoreData,
    essImportingMinimalDataSet,
    
    essCheckingForiCloudStore,
    essValidatingUbiquityToken,
    essEnableiCloudPrompt,
    essReadyToInitialiseDataStore,
    
    essMigrateLocalDataToCloud,
    essMigrateCloudDataToLocal,
    essReadyToLoadStore,
    
    essDataStoreOnline
} StoreState;

@protocol ICLCoreDataManagerDelegate;

#define ICLCoreDataManagerInstance [ICLCoreDataManager Instance]

@interface ICLCoreDataManager : NSObject

@property (weak, nonatomic) id <ICLCoreDataManagerDelegate> delegate;

@property (readonly, strong, nonatomic) NSManagedObjectContext* managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;

@property (nonatomic, strong) NSURL* storeURL;
@property (nonatomic, strong) NSDictionary* storeOptions;

@property (nonatomic, strong) ICLAlertViewController* iCloudEnableView;
@property (nonatomic, strong) ICLAlertViewController* migrateFromCloudView;
@property (nonatomic, strong) ICLAlertViewController* migrateToCloudView;
@property (nonatomic, strong) UIAlertView* accountChangedView;
@property (nonatomic, assign) StoreState currentState;
@property (nonatomic, strong) NSCondition* canFinishLoadingDataStore;
@property (nonatomic, assign) BOOL requestFinishLoadingDataStoreReceived;

@property (nonatomic, strong) NSNumber* undoLevel;

@property (nonatomic, strong) UIColor* Colour_AlertView_Button1;
@property (nonatomic, strong) UIColor* Colour_AlertView_Button2;
@property (nonatomic, strong) UIColor* Colour_AlertView_Panel1;
@property (nonatomic, strong) UIColor* Colour_AlertView_Panel2;

+ (ICLCoreDataManager*) Instance;

- (void) deviceListChanged:(NSNotification*) notification;

- (void) performBlock:(void (^)())block;
- (void) performBlockAndWait:(void (^)())block;

- (void) resetCoreDataInterfaces;
- (BOOL) isDataStoreOnline;
- (BOOL) iCloudAvailable;
- (BOOL) iCloudIsEnabled;

- (void) requestBeginLoadingDataStore;
- (void) requestFinishLoadingDataStore;

- (void) toggleiCloud:(BOOL) iCloudEnabled_New;

- (void) minimalDataImportWasPerformed;

- (void) saveContext;

- (NSURL *) applicationDocumentsDirectory;

- (void) beginUndoGroup;
- (void) endUndoGroup:(BOOL) applyUndo;

@end

@protocol ICLCoreDataManagerDelegate <NSObject>

@required

- (BOOL) performLegacyDataConversionIfRequired;
- (void) loadMinimalDataSet;

- (NSString*) storeName_Local;
- (NSString*) storeName_iCloud;

- (NSURL*) coreDataModelURL;

- (NSString*) backgroundImageNameForDialogs;

- (void) contextSaveNotification:(NSNotification*) notification;
- (void) storeDidImportUbiquitousContentChangesNotification:(NSNotification*) notification;
- (void) storeWillChangeNotification;
- (void) storeDidChangeNotification;
- (void) prepareForMigration:(BOOL) isLocalToiCloud;

@end;

