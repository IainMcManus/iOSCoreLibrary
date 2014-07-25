//
//  ISADataManager.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 11/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISADataManager.h"
#import "ISADataManager+DBMaintenance.h"

#import "Pet+Extensions.h"
#import "Owner+Extensions.h"
#import "Classification+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

NSString* Setting_iCloudEnabledChanged = @"iCloud.EnabledChanged";
NSString* Setting_NewiCloudEnabled = @"iCloud.NewiCloudEnabled";

NSString* Notification_LoadedNewVC = @"ISA.Notification.LoadedNewViewController";

UIColor* Colour_AlertView_Button1 = nil;
UIColor* Colour_AlertView_Button2 = nil;
UIColor* Colour_AlertView_Panel1 = nil;
UIColor* Colour_AlertView_Panel2 = nil;

@interface ISADataManager() <ICLCoreDataManagerDelegate>
- (id)initInstance;
@end;

@implementation ISADataManager {
    UIViewController* currentViewController;
    
    NSMutableArray* storeChangedDelegates;
    NSMutableArray* petChangedDelegates;
    NSMutableArray* ownerChangedDelegates;
    NSMutableArray* classificationChangedDelegates;
}

- (id) initInstance {
    if ((self = [super init])) {
        Colour_AlertView_Button1 = [UIColor colorWithHue:220.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
        Colour_AlertView_Button2 = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
        Colour_AlertView_Panel1 = [UIColor colorWithHue:210.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
        Colour_AlertView_Panel2 = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
        
        storeChangedDelegates = [[NSMutableArray alloc] init];
        petChangedDelegates = [[NSMutableArray alloc] init];
        ownerChangedDelegates = [[NSMutableArray alloc] init];
        classificationChangedDelegates = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (ISADataManager*) Instance {
    static ISADataManager* _instance = nil;
    
    // already initialised so we can exit
    if (_instance != nil) {
        return _instance;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    // allocate with the GCD - thread safe
    static dispatch_once_t dispatch;
    dispatch_once(&dispatch, ^(void) {
        _instance = [[ISADataManager alloc] initInstance];
    });
#else
    // allocate using old approach - thread safe but slower
    @synchronized([MLADataManager class]) {
        if (_instance == nil) {
            _instance = [[MLADataManager alloc] initInstance];
        }
    }
#endif
    
    return _instance;
}

- (void) applicationInitialised {
    [ICLCoreDataManager Instance].delegate = self;
    
    [ICLCoreDataManager Instance].Colour_AlertView_Button1 = Colour_AlertView_Button1;
    [ICLCoreDataManager Instance].Colour_AlertView_Button2 = Colour_AlertView_Button2;
    [ICLCoreDataManager Instance].Colour_AlertView_Panel1 = Colour_AlertView_Panel1;
    [ICLCoreDataManager Instance].Colour_AlertView_Panel2 = Colour_AlertView_Panel2;
    
    currentViewController = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadedNewVC:) name:Notification_LoadedNewVC object:nil];
    
    [[ICLCoreDataManager Instance] requestBeginLoadingDataStore];
}

- (void)loadedNewVC:(NSNotification *) notification {
    if([notification userInfo][@"viewController"]) {
        // if this is the first view we have become aware of then the UI is ready and we can finish loading the data
        if (!currentViewController) {
            [[ICLCoreDataManager Instance] requestFinishLoadingDataStore];
        }
        
        currentViewController = [notification userInfo][@"viewController"];
    }
}

- (UIViewController*) currentViewController {
    return currentViewController;
}

#pragma mark ICLCoreDataManagerDelegate Support

- (BOOL) performLegacyDataConversionIfRequired {
    return NO;
}

- (void) loadMinimalDataSet {
    [self loadMinimalDataSetIfRequired];
}

- (NSString*) storeName_Local {
    return @"ISAStore_Local";
}

- (NSString*) storeName_iCloud {
    return @"ISAStore_iCloud";
}

- (NSURL*) modelURL {
    return [[NSBundle mainBundle] URLForResource:@"CoreData" withExtension:@"momd"];
}

- (NSString*) backgroundImageNameForDialogs {
    return @"";
}

- (void) contextSaveNotification:(NSNotification*) notification {
}

- (void) storeWillChangeNotification {
    [self eventStoreWillChange];
}

- (void) storeDidChangeNotification {
    [self loadMinimalDataSetIfRequired];

    [[ICLCoreDataManager Instance] saveContext];

    [self performDataDeduplication];

    [self eventStoreDidChange];
}

- (void) storeDidImportUbiquitousContentChangesNotification:(NSNotification*) notification {
    NSManagedObjectContext* context = [[ICLCoreDataManager Instance] managedObjectContext];
    
    NSDictionary* changes = notification.userInfo;

    // Notify any registered listeners that an object was deleted.
    for (NSManagedObjectID* deletedObjectId in changes[NSDeletedObjectsKey]) {
        NSManagedObject* deletedObject = [context existingObjectWithID:deletedObjectId error:nil];
        
        if ([deletedObject isKindOfClass:[Pet class]]) {
            [self eventPetDeleted:(Pet*)deletedObject remoteChange:YES];
        }
        else if ([deletedObject isKindOfClass:[Owner class]]) {
            [self eventOwnerDeleted:(Owner*)deletedObject remoteChange:YES];
        }
        else if ([deletedObject isKindOfClass:[Classification class]]) {
            [self eventClassificationDeleted:(Classification*)deletedObject remoteChange:YES];
        }
    }

    // Notify any registered listeners that a new object was added.
    for (NSManagedObjectID* addedObjectId in changes[NSInsertedObjectsKey]) {
        NSManagedObject* addedObject = [context existingObjectWithID:addedObjectId error:nil];
        
        if ([addedObject isKindOfClass:[Pet class]]) {
            [self eventPetAdded:(Pet*)addedObject remoteChange:YES];
        }
        else if ([addedObject isKindOfClass:[Owner class]]) {
            [self eventOwnerAdded:(Owner*)addedObject remoteChange:YES];
        }
        else if ([addedObject isKindOfClass:[Classification class]]) {
            [self eventClassificationAdded:(Classification*)addedObject remoteChange:YES];
        }
    }
    
    // Notify any registered listeners that an existing object was modified.
    for (NSManagedObjectID* updatedObjectId in changes[NSUpdatedObjectsKey]) {
        NSManagedObject* updatedObject = [context existingObjectWithID:updatedObjectId error:nil];
        
        if ([updatedObject isKindOfClass:[Pet class]]) {
            [self eventPetUpdated:(Pet*)updatedObject remoteChange:YES];
        }
        else if ([updatedObject isKindOfClass:[Owner class]]) {
            [self eventOwnerUpdated:(Owner*)updatedObject remoteChange:YES];
        }
        else if ([updatedObject isKindOfClass:[Classification class]]) {
            [self eventClassificationUpdated:(Classification*)updatedObject remoteChange:YES];
        }
    }
    
    // Run the de-duplication. This MUST NOT be run before processing deletes.
    // If it is then none of the objects will be found.
    [self performDataDeduplication];
}

- (void) eventStoreWillChange {
    // Prevent user interaction until the store comes back online.
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    // Notify all registered handlers to prepare for the store going away.
    // Any held NSManagedObjects will be invalidated and can no longer be used.
    for (id eventHandler in storeChangedDelegates) {
        [eventHandler storeWillChange];
    }
}

- (void) eventStoreDidChange {
    // Permit user interaction again.
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
    
    // If we have a current view and it does not gracefully handle the store changes then force a reset
    // back to the main view.
    if (currentViewController && ![currentViewController conformsToProtocol:@protocol(StoreChangedDelegate)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Clear all delegates as we are fully resetting the user interface
            [storeChangedDelegates removeAllObjects];
            [petChangedDelegates removeAllObjects];
            [ownerChangedDelegates removeAllObjects];
            [classificationChangedDelegates removeAllObjects];
            
            // Load the main storyboard
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            // Instantiate a new view with the storyboard id MainView
            UIViewController* viewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainView"];
            
            // Switch to the new view
            id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
            appDelegate.window.rootViewController = viewController;
            [appDelegate.window makeKeyAndVisible];
        });
    } // Otherwise notify all registered handlers to reload data and refresh the UI.
    else {
        for (id eventHandler in storeChangedDelegates) {
            [eventHandler storeDidChange];
        }
    }
}

- (void) registerStoreChangedDelegate:(id) inHandler {
    [storeChangedDelegates addObject:inHandler];
}

- (void) unregisterStoreChangedDelegate:(id) inHandler {
    [storeChangedDelegates removeObject:inHandler];
}

#pragma mark Internal Handlers for Object Changes

- (void) registerPetChangedDelegate:(id) inHandler {
    [petChangedDelegates addObject:inHandler];
}

- (void) unregisterPetChangedDelegate:(id) inHandler {
    [petChangedDelegates removeObject:inHandler];
}

- (void) registerOwnerChangedDelegate:(id) inHandler {
    [ownerChangedDelegates addObject:inHandler];
}

- (void) unregisterOwnerChangedDelegate:(id) inHandler {
    [ownerChangedDelegates removeObject:inHandler];
}

- (void) registerClassificationChangedDelegate:(id) inHandler {
    [classificationChangedDelegates addObject:inHandler];
}

- (void) unregisterClassificationChangedDelegate:(id) inHandler {
    [classificationChangedDelegates removeObject:inHandler];
}

- (void) eventPetAdded:(Pet*) pet remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in petChangedDelegates) {
        [eventHandler petAdded:pet remoteChange:isRemoteChange];
    }
}

- (void) eventPetUpdated:(Pet*) pet remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in petChangedDelegates) {
        [eventHandler petUpdated:pet remoteChange:isRemoteChange];
    }
}

- (void) eventPetDeleted:(Pet*) pet remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in petChangedDelegates) {
        [eventHandler petDeleted:pet remoteChange:isRemoteChange];
    }
}

- (void) eventOwnerAdded:(Owner*) owner remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in ownerChangedDelegates) {
        [eventHandler ownerAdded:owner remoteChange:isRemoteChange];
    }
}

- (void) eventOwnerUpdated:(Owner*) owner remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in ownerChangedDelegates) {
        [eventHandler ownerUpdated:owner remoteChange:isRemoteChange];
    }
}

- (void) eventOwnerDeleted:(Owner*) owner remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in ownerChangedDelegates) {
        [eventHandler ownerDeleted:owner remoteChange:isRemoteChange];
    }
}

- (void) eventClassificationAdded:(Classification*) classification remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in classificationChangedDelegates) {
        [eventHandler classificationAdded:classification remoteChange:isRemoteChange];
    }
}

- (void) eventClassificationUpdated:(Classification*) classification remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in classificationChangedDelegates) {
        [eventHandler classificationUpdated:classification remoteChange:isRemoteChange];
    }
}

- (void) eventClassificationDeleted:(Classification*) classification remoteChange:(BOOL) isRemoteChange {
    for (id eventHandler in classificationChangedDelegates) {
        [eventHandler classificationDeleted:classification remoteChange:isRemoteChange];
    }
}

@end
