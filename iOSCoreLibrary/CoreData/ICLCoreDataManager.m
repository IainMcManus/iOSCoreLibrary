//
//  ICLCoreDataManager.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 2/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLCoreDataManager.h"

#import "ICLCoreDataDeviceList.h"
#import "NSURL+InternalExtensions.h"

#import "Reachability.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"
#import "NSBundle+InternalExtensions.h"

NSString* Setting_LegacyDataConversionPerformed = @"LegacyDataConversionPerformed";
NSString* Setting_MinimalDataImportPerformed = @"MinimalDataImportPerformed";

NSString* Setting_iCloudEnabled = @"iCloud.Enabled";
NSString* Setting_IdentityToken = @"iCloud.IdentityToken";
NSString* Setting_MigrationToCloudPerformedBase = @"iCloud.%@.MigrationPerformedToCloud";
NSString* Setting_MigrationFromCloudPerformedBase = @"iCloud.%@.MigrationPerformedFromCloud";

NSString* Setting_iCloudUUID = @"iCloud.UUID";
NSString* iCloudDeviceListName = @"ICLKnownDevices.plist";

@interface ICLCoreDataManager() <ICLAlertViewControllerDelegate, UIAlertViewDelegate>
- (id)initInstance;
@end

@implementation ICLCoreDataManager {
    ICLCoreDataDeviceList* _deviceList;
    NSMetadataQuery* _deviceListMetadataQuery;
    NSArray* _knownDeviceUUIDs;
    
    BOOL _iCloudStoreExists;
    
    dispatch_queue_t _backgroundQueue;
    
    BOOL _accountChanged;
    
    BOOL _firstTimeOnline;
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (id) initInstance {
    if ((self = [super init])) {
        _currentState = essUninitialised;
        _undoLevel = @(0);
        _accountChanged = NO;
        
        _deviceList = nil;
        _iCloudStoreExists = NO;
        
        _firstTimeOnline = YES;
        
        _backgroundQueue = dispatch_queue_create("ICLCoreDataManager.BackgroundQueue", NULL);
        
        // create the iCloud UUID if it is missing
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults objectForKey:Setting_iCloudUUID]) {
            [userDefaults setObject:[[NSUUID UUID] UUIDString] forKey:Setting_iCloudUUID];
            [userDefaults synchronize];
        }
    }
    
    return self;
}

+ (ICLCoreDataManager*) Instance {
    static ICLCoreDataManager* _instance = nil;
    
    // already initialised so we can exit
    if (_instance != nil) {
        return _instance;
    }
    
    // allocate with the GCD - thread safe
    static dispatch_once_t dispatch;
    dispatch_once(&dispatch, ^(void) {
        _instance = [[ICLCoreDataManager alloc] initInstance];
    });
    
    return _instance;
}

#pragma mark Device List Handling

- (void) setupDeviceList {
    // device list is not relevant if iCloud is not supported
    if (![self iCloudAvailable]) {
        return;
    }
    
    _knownDeviceUUIDs = nil;
    
    // setup the device list document
    _deviceList = [[ICLCoreDataDeviceList alloc] initWithURLAndQueue:[self deviceListURL] queue:[[NSOperationQueue alloc] init]];
    
    // add the device list document as a file presenter
    [NSFileCoordinator addFilePresenter:_deviceList];
    
    // monitor for any changes to the file on iCloud
    _deviceListMetadataQuery = [[NSMetadataQuery alloc] init];
    _deviceListMetadataQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope];
    _deviceListMetadataQuery.predicate = [NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey, iCloudDeviceListName];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceListChanged:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:_deviceListMetadataQuery];
    
    // metadata queries must be started on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [_deviceListMetadataQuery startQuery];
    });
}

- (void) teardownDeviceList {
    // if iCloud was not available then the device list will never have been setup
    if (_deviceList) {
        [NSFileCoordinator removeFilePresenter:_deviceList];
        _deviceList = nil;
        
        _knownDeviceUUIDs = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:_deviceListMetadataQuery];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_deviceListMetadataQuery stopQuery];
            _deviceListMetadataQuery = nil;
        });
    }
}

- (void) deviceListChanged:(NSNotification*) notification {
    dispatch_async(_backgroundQueue, ^{
        @synchronized(_backgroundQueue) {
            // prevent any other change notifications while we are processing the updated list
            [_deviceListMetadataQuery disableUpdates];
            
            // force the device list to refresh
            [self refreshDeviceList:NO completionHandler:^(BOOL deviceListExisted, BOOL currentDevicePresent) {
                // allow change notifications again
                [_deviceListMetadataQuery enableUpdates];
            }];
        }
    });
}

- (void) refreshDeviceList:(BOOL) canAddCurrentDevice completionHandler:(void (^)(BOOL deviceListExisted, BOOL currentDevicePresent))completionHandler {
    _knownDeviceUUIDs = nil;
    
    NSString* iCloudUUID = [[NSUserDefaults standardUserDefaults] stringForKey:Setting_iCloudUUID];
    
    // force synchronise the device list document
    NSURL* fileURL = [self deviceListURL];
    [fileURL forceSyncFile:_backgroundQueue completion:^(BOOL syncCompleted, NSError* error) {
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:_deviceList];
        error = nil;
        
        __block BOOL deviceListExisted = NO;
        __block BOOL currentDevicePresent = NO;
        
        // attempt to read the device list
        [coordinator coordinateReadingItemAtURL:fileURL options:0 error:&error byAccessor:^(NSURL *readURL) {
            NSDictionary* deviceList = [NSDictionary dictionaryWithContentsOfURL:readURL];
            _knownDeviceUUIDs = [deviceList objectForKey:@"DeviceUUIDs"];
            
            deviceListExisted = _knownDeviceUUIDs && ([_knownDeviceUUIDs count] > 0);
            currentDevicePresent = deviceListExisted && [_knownDeviceUUIDs containsObject:iCloudUUID];
        }];
        
        // if the current device isn't present in the file then add it
        if (!currentDevicePresent && canAddCurrentDevice) {
            // create the updated list of UUIDs
            NSMutableArray* newKnownDeviceUUIDs = _knownDeviceUUIDs ? [_knownDeviceUUIDs mutableCopy] : [[NSMutableArray alloc] init];
            [newKnownDeviceUUIDs addObject:iCloudUUID];
            
            // generate the dictionary for the plist
            NSDictionary* newDeviceList = @{@"DeviceUUIDs" : newKnownDeviceUUIDs};
            
            // make sure the remote location exists
            NSURL* iCloudURLBase = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
            [coordinator coordinateWritingItemAtURL:iCloudURLBase options:0 error:NULL byAccessor:^(NSURL *newURL) {
                [[NSFileManager defaultManager] createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
            }];
            
            // write the updated file
            [coordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *writeURL) {
                [newDeviceList writeToURL:writeURL atomically:NO];
            }];
        }
        
        completionHandler(deviceListExisted, currentDevicePresent);
    }];
}

#pragma mark Main Core Data Interfaces

- (void) performBlock:(void (^)())block {
    if ((self.managedObjectContext.concurrencyType == NSMainQueueConcurrencyType) &&
        [NSThread currentThread].isMainThread) {
        block();
    }
    else {
        [self.managedObjectContext performBlock:^{
            block();
        }];
    }
}

- (void) performBlockAndWait:(void (^)())block {
    if ((self.managedObjectContext.concurrencyType == NSMainQueueConcurrencyType) &&
        [NSThread currentThread].isMainThread) {
        block();
    }
    else {
        [self.managedObjectContext performBlockAndWait:^{
            block();
        }];
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        // it's possible that it got created as a result of creating the coordinator
        if (_managedObjectContext) {
            return _managedObjectContext;
        }
        
        if (self.currentState >= essReadyToLoadStore) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
            [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
            
            [_managedObjectContext setUndoManager:[[NSUndoManager alloc] init]];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(contextSaveNotification:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:[self managedObjectContext]];
        }
        else {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
            [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        }
    }
    
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[self.delegate coreDataModelURL]];
    [_managedObjectModel kc_generateOrderedSetAccessors];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (self.currentState == essReadyToLoadStore) {
        [self CoreData_RegisterForNotifications:_persistentStoreCoordinator];
    }
    
    NSMutableDictionary* workingOptions = [self.storeOptions mutableCopy];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:workingOptions error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (void) contextSaveNotification:(NSNotification*) notification {
    [self.delegate contextSaveNotification:notification];
}

- (void) saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    
    if (managedObjectContext != nil) {
        [ICLCoreDataManagerInstance performBlockAndWait:^{
            NSError *error = nil;
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
        }];
    }
}

- (void) resetCoreDataInterfaces {
    if (_managedObjectContext) {
        [_managedObjectContext lock];
        
        __block NSError *error;
        __block BOOL savedOK = NO;
        [ICLCoreDataManagerInstance performBlockAndWait:^{
            savedOK = [_managedObjectContext save:&error];
        }];
        
        [_managedObjectContext unlock];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:_managedObjectContext];
    }
    
    if (_persistentStoreCoordinator) {
        [self CoreData_UnregisterForNotifications];
        
        for (NSPersistentStore* store in _persistentStoreCoordinator.persistentStores) {
            [_persistentStoreCoordinator removePersistentStore:store error:nil];
        }
    }
    
    _persistentStoreCoordinator = nil;
    
    _managedObjectContext = nil;
}

#pragma mark Information Retrieval Methods

- (NSString*) storeName_Local {
    return [self.delegate storeName_Local];
}

- (NSString*) storeName_iCloud {
    return [self.delegate storeName_iCloud];
}

- (NSURL*) storeURL_Local {
    return [[[self applicationDocumentsDirectory] URLByAppendingPathComponent:[self storeName_Local]] URLByAppendingPathExtension:@"sqlite"];
}

- (NSURL*) storeURL_iCloud {
    return [[[self applicationDocumentsDirectory] URLByAppendingPathComponent:[self storeName_iCloud]] URLByAppendingPathExtension:@"sqlite"];
}

- (NSURL*) deviceListURL {
    NSURL* iCloudURLBase = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    
    NSString* deviceList = [[iCloudURLBase path] stringByAppendingPathComponent:iCloudDeviceListName];
    
    return [NSURL fileURLWithPath:deviceList];
}

- (NSDictionary*) storeOptions_Local {
    return @{NSMigratePersistentStoresAutomaticallyOption: @YES,
             NSInferMappingModelAutomaticallyOption: @YES,
             NSSQLitePragmasOption: @{@"journal_mode" : @"DELETE"}};
}

- (NSDictionary*) storeOptions_iCloud {
    return @{NSMigratePersistentStoresAutomaticallyOption: @YES,
             NSInferMappingModelAutomaticallyOption: @YES,
             NSPersistentStoreUbiquitousContentNameKey: [self storeName_iCloud],
             NSSQLitePragmasOption: @{@"journal_mode" : @"DELETE"}};
}

- (BOOL) isDataStoreOnline {
    return self.currentState == essDataStoreOnline;
}

- (BOOL) iCloudAvailable {
    return ([self ubiquityIdentityToken] != nil) &&
    ([[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] != nil);
}

- (BOOL) iCloudIsEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:Setting_iCloudEnabled];
}

- (void) minimalDataImportWasPerformed {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setBool:YES forKey:Setting_MinimalDataImportPerformed];
    
    [userDefaults synchronize];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (id) ubiquityIdentityToken {
    if (Using_iOS7OrAbove &&
        ([[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] != nil)) {
        return [[NSFileManager defaultManager] ubiquityIdentityToken];
    }
    else {
        return nil;
    }
}

- (BOOL) isLocalStorePresent {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self storeURL_Local] path]];
}

- (BOOL) isiCloudStorePresent {
    return _iCloudStoreExists;
}

#pragma mark iCloud Enable/Disable

- (void) toggleiCloud:(BOOL) iCloudEnabled_New {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setBool:iCloudEnabled_New forKey:Setting_iCloudEnabled];
    [userDefaults synchronize];
    
    id identityToken = [self ubiquityIdentityToken];
    NSString* tokenString = identityToken ? [[NSKeyedArchiver archivedDataWithRootObject:identityToken] base64Encoding] : nil;
    
    // user has enabled iCloud
    if ([userDefaults boolForKey:Setting_iCloudEnabled]) {
        NSString* Setting_MigrationToCloudPerformed = [NSString stringWithFormat:Setting_MigrationToCloudPerformedBase, tokenString];
        
        // Clear the migration performed flag as it is likely been a long time since we did migrate
        [userDefaults removeObjectForKey:Setting_MigrationToCloudPerformed];
    } // user has disabled iCloud
    else {
        NSString* Setting_MigrationFromCloudPerformed = identityToken ? [NSString stringWithFormat:Setting_MigrationFromCloudPerformedBase, tokenString] : nil;
        
        // Clear the migration performed flag as it is likely been a long time since we did migrate
        [userDefaults removeObjectForKey:Setting_MigrationFromCloudPerformed];
    }
    [userDefaults synchronize];
    
    // Give the UI a chance to prepare for the change
    [self.delegate storeWillChangeNotification];
    
    // Set the state machine to Checking for iCloud Store - it will handle migration
    self.currentState = essCheckingForiCloudStore;
    
    // Enter the FSM
    [self requestLoadDataStore];
}

#pragma mark iCloud Enable/Disable Internal

- (void) switchStoreToiCloud {
    if (![self.storeURL isEqual:[self storeURL_iCloud]]) {
        self.storeURL = [self storeURL_iCloud];
        self.storeOptions = [self storeOptions_iCloud];
        
        [self resetCoreDataInterfaces];
    }
}

- (void) switchStoreToLocal {
    if (![self.storeURL isEqual:[self storeURL_Local]]) {
        self.storeURL = [self storeURL_Local];
        self.storeOptions = [self storeOptions_Local];
        
        [self resetCoreDataInterfaces];
    }
}

#pragma mark Finite State Machine Main Loop

- (void) requestBeginLoadingDataStore {
    assert(self.currentState == essUninitialised);
    
    self.requestFinishLoadingDataStoreReceived = NO;
    
    [self requestLoadDataStore];
}

- (void) requestFinishLoadingDataStore {
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    if (!self.requestFinishLoadingDataStoreReceived) {
        [self.canFinishLoadingDataStore signal];
        self.requestFinishLoadingDataStoreReceived = YES;
    }
}

- (void) requestLoadDataStore {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self requestLoadDataStore_Internal];
    });
}

- (void) requestLoadDataStore_Internal {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    BOOL noConnectivity = [networkReachability currentReachabilityStatus] == NotReachable;
    
    // initial setup stage
    if (self.currentState == essUninitialised) {
        self.canFinishLoadingDataStore = self.requestFinishLoadingDataStoreReceived ? nil : [[NSCondition alloc] init];
        
        [self setupDeviceList];
        
        [userDefaults setBool:NO forKey:Setting_MinimalDataImportPerformed];
        [userDefaults synchronize];
        
        __block BOOL isLocalStorePresent = [self isLocalStorePresent];
        
        // always default to the local store
        self.storeURL = [self storeURL_Local];
        self.storeOptions = [self storeOptions_Local];
        
        // If the underlying data has not been converted to core data then perform the conversion
        if (![userDefaults boolForKey:Setting_LegacyDataConversionPerformed]) {
            // Enter conversion of legacy data state
            self.currentState = essConvertingLegacyDataToCoreData;
            
            // Perform the legacy data import and save the results
            [ICLCoreDataManagerInstance performBlockAndWait:^{
                // if the legacy conversion returned YES then we must now have a local store
                isLocalStorePresent |= [self.delegate performLegacyDataConversionIfRequired];
                
                [self saveContext];
            }];
            
            [userDefaults setBool:YES forKey:Setting_LegacyDataConversionPerformed];
            [userDefaults synchronize];
        }
        
        // Are we running a version of iOS below 7?
        // If so iCloud will not be used due to reliablilty issues.
        if (!Using_iOS7OrAbove) {
            // Force iCloud to be disabled by disabling the flag and removing any stored identity token
            [userDefaults setBool:NO forKey:Setting_iCloudEnabled];
            [userDefaults removeObjectForKey:Setting_IdentityToken];
            [userDefaults synchronize];
        }
        
        // The local store should always be present. If it is not at this point then we recreate it with minimal data
        if (!isLocalStorePresent) {
            // flag the minimal data import as performed
            [userDefaults setBool:YES forKey:Setting_MinimalDataImportPerformed];
            [userDefaults synchronize];
            
            // Load the minimal data set
            self.currentState = essImportingMinimalDataSet;
            
            // Load the bare minimum of data required to function
            [ICLCoreDataManagerInstance performBlockAndWait:^{
                [self.delegate loadMinimalDataSet];
                [self saveContext];
            }];
        }
        
        self.currentState = essCheckingForiCloudStore;
    }
    
    id identityToken = [self ubiquityIdentityToken];
    
    // we have not yet check if the iCloud store is already present
    if (self.currentState == essCheckingForiCloudStore) {
        // kick off an initial query to start the downloading in the background
        if (identityToken && !noConnectivity) {
            dispatch_sync(_backgroundQueue, ^{
                [self refreshDeviceList:NO completionHandler:^(BOOL deviceListExisted, BOOL currentDevicePresent) {
                    _iCloudStoreExists = deviceListExisted;
                }];
            });
        }
        
        // we may have already been requested to proceed
        if (!self.requestFinishLoadingDataStoreReceived) {
            [self.canFinishLoadingDataStore lock];
            [self.canFinishLoadingDataStore wait];
            [self.canFinishLoadingDataStore unlock];
        }
        
        self.currentState = essValidatingUbiquityToken;
        
        // refresh connectivity at this point
        noConnectivity = [networkReachability currentReachabilityStatus] == NotReachable;
    }
    
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    // We have performed the initial setup so we know that local data exists.
    // We now need to validate the ubiquity token and check if the user has made a choice on enabling iCloud
    if (self.currentState == essValidatingUbiquityToken) {
        // iCloud is supported for this user - check if the user has changed and warn accordingly
        if (identityToken) {
            NSData* previousTokenData = [userDefaults objectForKey:Setting_IdentityToken];
            id previousIdentityToken = previousTokenData ? [NSKeyedUnarchiver unarchiveObjectWithData:previousTokenData] : nil;
            
            [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:identityToken] forKey:Setting_IdentityToken];
            [userDefaults synchronize];
            
            // The token has changed - warn the user so they know the data won't be present
            if (previousIdentityToken && ![identityToken isEqual:previousIdentityToken]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString* msgTitle = NSLocalizedStringFromTableInBundle(@"iCloud.AccountChanged.Title", @"ICL_iCloud", [NSBundle localisationBundle], @"iCloud Account Changed");
                    NSString* msgBody = NSLocalizedStringFromTableInBundle(@"iCloud.AccountChanged.Body", @"ICL_iCloud", [NSBundle localisationBundle], @"You have signed into a different iCloud account.");
                    
                    self.accountChangedView = [[UIAlertView alloc] initWithTitle:msgTitle
                                                                         message:msgBody
                                                                        delegate:nil
                                                               cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok")
                                                               otherButtonTitles:nil];
                    
                    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    }
                    
                    self.accountChangedView.delegate = self;
                    
                    NSString* tokenString = identityToken ? [[NSKeyedArchiver archivedDataWithRootObject:identityToken] base64Encoding] : nil;
                    
                    NSString* Setting_MigrationToCloudPerformed = [NSString stringWithFormat:Setting_MigrationToCloudPerformedBase, tokenString];
                    NSString* Setting_MigrationFromCloudPerformed = identityToken ? [NSString stringWithFormat:Setting_MigrationFromCloudPerformedBase, tokenString] : nil;
                    
                    // Clear iCloud and migration related flags to force the user to make the choice again
                    [userDefaults removeObjectForKey:Setting_iCloudEnabled];
                    [userDefaults removeObjectForKey:Setting_MigrationToCloudPerformed];
                    [userDefaults removeObjectForKey:Setting_MigrationFromCloudPerformed];
                    [userDefaults synchronize];
                    
                    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    }
                    [self.accountChangedView show];
                });
                
                // We can safely exit at this point and re-enter the state machine later.
                return;
            }
            
            // if iCloud is supported but the user hasn't decided if they want to enable it or not yet
            BOOL iCloudEnablePromptRequired = !previousTokenData || ![userDefaults objectForKey:Setting_iCloudEnabled];
            
            // need to setup iCloud but it is unreachable
            if (iCloudEnablePromptRequired && noConnectivity) {
                // nothing to do at this point
            }
            else if (iCloudEnablePromptRequired) {
                self.currentState = essEnableiCloudPrompt;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString* msgTitle = NSLocalizedStringFromTableInBundle(@"iCloud.Enable.Title", @"ICL_iCloud", [NSBundle localisationBundle], @"Data Storage Selection");
                    
                    NSString* option_iCloud = NSLocalizedStringFromTableInBundle(@"iCloud", @"ICL_iCloud", [NSBundle localisationBundle], @"iCloud");
                    NSString* description_iCloud = NSLocalizedStringFromTableInBundle(@"iCloudDescription", @"ICL_iCloud", [NSBundle localisationBundle], @"All application data will be stored in iCloud. If you have multiple devices connected to the same iCloud account then the data will be synchronised between them.");
                    
                    NSString* option_Locally = NSLocalizedStringFromTableInBundle(@"Locally", @"ICL_iCloud", [NSBundle localisationBundle], @"Locally");
                    NSString* description_Locally = NSLocalizedStringFromTableInBundle(@"LocallyDescription", @"ICL_iCloud", [NSBundle localisationBundle], @"All application data will be stored locally on the device. If you have multiple devices then the data will not be synchronised between them.");

                    NSDictionary* appearance = @{kICLButton1Colour: self.Colour_AlertView_Button1,
                                                 kICLButton2Colour: self.Colour_AlertView_Button2,
                                                 kICLPanel1Colour: self.Colour_AlertView_Panel1,
                                                 kICLPanel2Colour: self.Colour_AlertView_Panel2,
                                                 kICLBackgroundImage: [self.delegate backgroundImageNameForDialogs]};
                    
                    self.iCloudEnableView = [ICLAlertViewController create:msgTitle
                                                               optionNames:@[option_iCloud, option_Locally]
                                                        optionDescriptions:@[description_iCloud, description_Locally]
                                                         appearanceOptions:appearance];
                    self.iCloudEnableView.delegate = self;
                    
                    [self.iCloudEnableView show];
                    
                    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    }
                });
                
                // must exit at this point - function is re-entered by the alert view
                return;
            }
            
            self.currentState = essReadyToInitialiseDataStore;
        }
        else {
            [self forceLocalStoreAndDisableiCloud];
            
            self.currentState = essReadyToInitialiseDataStore;
        }
    }
    
    // The user has made a choice if iCloud can be enabled or not
    if (self.currentState == essReadyToInitialiseDataStore) {
        NSString* tokenString = identityToken ? [[NSKeyedArchiver archivedDataWithRootObject:identityToken] base64Encoding] : nil;
        
        // User has elected to enable iCloud and it is supported
        if ([userDefaults boolForKey:Setting_iCloudEnabled]) {
            NSString* Setting_MigrationToCloudPerformed = [NSString stringWithFormat:Setting_MigrationToCloudPerformedBase, tokenString];
            
            // Migration cannot be performed if we have just done a minimal import
            // AND
            // Migration to the Cloud has not already been performed
            if (![userDefaults boolForKey:Setting_MigrationToCloudPerformed] &&
                ![userDefaults boolForKey:Setting_MinimalDataImportPerformed]) {
                self.currentState = essMigrateLocalDataToCloud;
                
                // iCloud data is present - prompt to perform the migration
                if ([self isiCloudStorePresent]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                        
                        NSString* msgTitle = NSLocalizedStringFromTableInBundle(@"iCloud.MigrateToCloud.Title", @"ICL_iCloud", [NSBundle localisationBundle], @"Migrate Data To Cloud");
                        
                        NSString* option_Migrate = NSLocalizedStringFromTableInBundle(@"iCloud.MigrateToCloud", @"ICL_iCloud", [NSBundle localisationBundle], @"Merge iCloud Data");
                        NSString* description_MigrateString = NSLocalizedStringFromTableInBundle(@"iCloud.MigrateToCloudDescription", @"ICL_iCloud", [NSBundle localisationBundle], @"This will merge all of your local data with your iCloud data for %@. Your local data will not be changed.\n\nAll local data will not be accessible until iCloud is disabled.");
                        NSString* description_Migrate = [NSString stringWithFormat:description_MigrateString, appName, appName];
                        
                        NSString* option_NoMigrate = NSLocalizedStringFromTableInBundle(@"iCloud.NoMigrateToCloud", @"ICL_iCloud", [NSBundle localisationBundle], @"Keep iCloud Data");
                        NSString* description_NoMigrate = NSLocalizedStringFromTableInBundle(@"iCloud.NoMigrateToCloudDescription", @"ICL_iCloud", [NSBundle localisationBundle], @"This will use the existing data on iCloud. Your local data will not be changed.\n\nAll local data will not be accessible until iCloud is disabled.");
                        
                        NSDictionary* appearance = @{kICLButton1Colour: self.Colour_AlertView_Button1,
                                                     kICLButton2Colour: self.Colour_AlertView_Button2,
                                                     kICLPanel1Colour: self.Colour_AlertView_Panel1,
                                                     kICLPanel2Colour: self.Colour_AlertView_Panel2,
                                                     kICLBackgroundImage: [self.delegate backgroundImageNameForDialogs]};
                        
                        self.migrateToCloudView = [ICLAlertViewController create:msgTitle
                                                                     optionNames:@[option_Migrate, option_NoMigrate]
                                                              optionDescriptions:@[description_Migrate, description_NoMigrate]
                                                               appearanceOptions:appearance];
                        self.migrateToCloudView.delegate = self;
                        
                        if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                        }
                        
                        [self.migrateToCloudView show];
                    });
                } // iCloud data is not present - no prompt required
                else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self migrateLocalStoreToCloud];
                    });
                }
                
                // must exit at this point - function is re-entered by the migration thread
                return;
            }
            else {
                // flag the import as already performed
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:Setting_MigrationToCloudPerformed];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self switchStoreToiCloud];
                
                self.currentState = essReadyToLoadStore;
            }
        } // iCloud is not being used (or is not supported)
        else {
            NSString* Setting_MigrationFromCloudPerformed = identityToken ? [NSString stringWithFormat:Setting_MigrationFromCloudPerformedBase, tokenString] : nil;
            
            // If we have a token
            //    AND there is data in the cloud
            //    AND migration has not been performed
            //    AND the network is reachable
            // then attempt to perform the migration.
            if (identityToken &&
                ![userDefaults boolForKey:Setting_MigrationFromCloudPerformed] &&
                [self isiCloudStorePresent] &&
                !noConnectivity) {
                self.currentState = essMigrateCloudDataToLocal;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                    
                    NSString* msgTitle = NSLocalizedStringFromTableInBundle(@"iCloud.MigrateFromCloud.Title", @"ICL_iCloud", [NSBundle localisationBundle], @"Migrate Data From Cloud");
                    
                    NSString* option_Migrate = NSLocalizedStringFromTableInBundle(@"iCloud.MigrateFromCloud", @"ICL_iCloud", [NSBundle localisationBundle], @"Replace Local Data");
                    NSString* description_MigrateString = NSLocalizedStringFromTableInBundle(@"iCloud.MigrateFromCloudDescription", @"ICL_iCloud", [NSBundle localisationBundle], @"This will replace all local data for %@ with your iCloud data.\n\nAll existing local data for %@ WILL BE OVERWRITTEN!");
                    NSString* description_Migrate = [NSString stringWithFormat:description_MigrateString, appName, appName];
                    
                    NSString* option_NoMigrate = NSLocalizedStringFromTableInBundle(@"iCloud.NoMigrateFromCloud", @"ICL_iCloud", [NSBundle localisationBundle], @"Keep Local Data");
                    NSString* description_NoMigrate = NSLocalizedStringFromTableInBundle(@"iCloud.NoMigrateFromCloudDescription", @"ICL_iCloud", [NSBundle localisationBundle], @"This will use the existing local data. Your iCloud data will not be changed.\n\nAll iCloud data will not be accessible until iCloud is enabled.");
                    
                    NSDictionary* appearance = @{kICLButton1Colour: self.Colour_AlertView_Button1,
                                                 kICLButton2Colour: self.Colour_AlertView_Button2,
                                                 kICLPanel1Colour: self.Colour_AlertView_Panel1,
                                                 kICLPanel2Colour: self.Colour_AlertView_Panel2,
                                                 kICLBackgroundImage: [self.delegate backgroundImageNameForDialogs]};
                    
                    self.migrateFromCloudView = [ICLAlertViewController create:msgTitle
                                                                   optionNames:@[option_Migrate, option_NoMigrate]
                                                            optionDescriptions:@[description_Migrate, description_NoMigrate]
                                                             appearanceOptions:appearance];
                    self.migrateFromCloudView.delegate = self;
                    
                    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    }
                    
                    [self.migrateFromCloudView show];
                });
                
                // must exit at this point - function is re-entered by the alert view
                return;
            }
            else {
                // flag the import as already performed if we have an identity token
                if (identityToken) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:Setting_MigrationFromCloudPerformed];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [self switchStoreToLocal];
                
                self.currentState = essReadyToLoadStore;
            }
        }
    }
    
    // Any migration has been performed and the data store may be loaded
    if (self.currentState == essReadyToLoadStore) {
        // Remove temporary flag
        [userDefaults removeObjectForKey:Setting_MinimalDataImportPerformed];
        [userDefaults synchronize];
        
        _accountChanged = NO;
        
        if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
        
        // refresh the device list and permit the current device to be added if iCloud is enabled
        if ([[self storeURL] isEqual:[self storeURL_iCloud]]) {
            _iCloudStoreExists = YES;
            
            dispatch_async(_backgroundQueue, ^{
                [self refreshDeviceList:YES completionHandler:^(BOOL deviceListExisted, BOOL currentDevicePresent) {
                }];
            });
        }

        [self resetCoreDataInterfaces];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self managedObjectContext];
        });
    }
}

#pragma mark Local Store Methods

- (void) deleteLocalStore {
    // file does not exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[self storeURL_Local] path]]) {
        return;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:[[self storeURL_Local] path] error:nil];
}

- (void) forceLocalStoreAndDisableiCloud {
    // force disable the iCloud store
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:Setting_iCloudEnabled];
    [userDefaults synchronize];
    
    [self switchStoreToLocal];
}

#pragma mark Alert View Handlers

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // No additional logic is required for the account changed view.
    // We can simply re-enter the state machine at it's current point.
    if (alertView == self.accountChangedView) {
        [self requestLoadDataStore];
    }
}

- (void)alertViewControllerDidFinish:(ICLAlertViewController *)alertView selectedOption:(NSUInteger)option {
    if (alertView == self.iCloudEnableView) {
        [[NSUserDefaults standardUserDefaults] setBool:(option == 1) forKey:Setting_iCloudEnabled];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.currentState = essReadyToInitialiseDataStore;
        
        [self requestLoadDataStore];
    }
    else if (alertView == self.migrateToCloudView) {
        if (option == 1) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self migrateLocalStoreToCloud];
            });
        } // user has selected not to import to the cloud. use all the cloud data but flag as if we have imported
        else {
            [self switchStoreToiCloud];
            
            self.currentState = essReadyToLoadStore;
            
            NSString* tokenString = [[NSKeyedArchiver archivedDataWithRootObject:[self ubiquityIdentityToken]] base64Encoding];
            NSString* Setting_MigrationToCloudPerformed = [NSString stringWithFormat:Setting_MigrationToCloudPerformedBase, tokenString];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:Setting_MigrationToCloudPerformed];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self requestLoadDataStore];
        }
    }
    else if (alertView == self.migrateFromCloudView) {
        if (option == 1) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self migrateCloudStoreToLocal:YES];
            });
        } // user has selected not to import from the cloud. use all the local data but flag as if we have imported
        else {
            [self switchStoreToLocal];
            
            self.currentState = essReadyToLoadStore;
            
            NSString* tokenString = [[NSKeyedArchiver archivedDataWithRootObject:[self ubiquityIdentityToken]] base64Encoding];
            NSString* Setting_MigrationFromCloudPerformed = [NSString stringWithFormat:Setting_MigrationFromCloudPerformedBase, tokenString];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:Setting_MigrationFromCloudPerformed];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self requestLoadDataStore];
        }
    }
}

#pragma mark Data Migration

- (void) migrateLocalStoreToCloud {
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    [self switchStoreToLocal];
    
    [ICLCoreDataManagerInstance performBlockAndWait:^{
        [self.delegate prepareForMigration:YES];
        
        NSError* error = nil;
        NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
        
        NSPersistentStore *store = [[coordinator persistentStores] firstObject];
        
        NSMutableDictionary *cloudStoreOptions = [[self storeOptions_iCloud] mutableCopy];
        
        NSPersistentStore *newStore = [coordinator migratePersistentStore:store
                                                                    toURL:[self storeURL_iCloud]
                                                                  options:cloudStoreOptions
                                                                 withType:NSSQLiteStoreType error:&error];
        
        if (error) {
            NSLog(@"Error: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        
        if (newStore) {
            [self switchStoreToiCloud];
            
            self.currentState = essReadyToLoadStore;
            
            NSString* tokenString = [[NSKeyedArchiver archivedDataWithRootObject:[self ubiquityIdentityToken]] base64Encoding];
            NSString* Setting_MigrationToCloudPerformed = [NSString stringWithFormat:Setting_MigrationToCloudPerformedBase, tokenString];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:Setting_MigrationToCloudPerformed];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else {
            [self forceLocalStoreAndDisableiCloud];
            
            self.currentState = essReadyToLoadStore;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString* msgTitle = NSLocalizedStringFromTableInBundle(@"iCloud.MigrationToCloudFailed.Title", @"ICL_iCloud", [NSBundle localisationBundle], @"iCloud Migration Failed");
                NSString* msgBody = NSLocalizedStringFromTableInBundle(@"iCloud.MigrationToCloudFailed.Body", @"ICL_iCloud", [NSBundle localisationBundle], @"Migration of the data to iCloud failed. iCloud will be disabled and the local data will be used. To attempt to switch back to iCloud go to the iCloud page in Global Settings.");
                
                UIAlertView* warning = [[UIAlertView alloc] initWithTitle:msgTitle message:msgBody delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok") otherButtonTitles:nil];
                
                if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                }
                
                [warning show];
            });
        }
        
        [self requestLoadDataStore];
    }];
}

- (void) migrateCloudStoreToLocal:(BOOL) overwrite {
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    [self switchStoreToiCloud];
    
    [ICLCoreDataManagerInstance performBlockAndWait:^{
        [self.delegate prepareForMigration:NO];
        
        if (overwrite) {
            [self deleteLocalStore];
        }
        
        NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
        
        NSPersistentStore *store = [[coordinator persistentStores] firstObject];
        
        NSMutableDictionary *localStoreOptions = [[self storeOptions_Local] mutableCopy];
        localStoreOptions[NSPersistentStoreRemoveUbiquitousMetadataOption] = @(YES);
        if (overwrite) {
            localStoreOptions[NSPersistentStoreRebuildFromUbiquitousContentOption] = @(YES);
        }
        
        NSPersistentStore *newStore =  [coordinator migratePersistentStore:store
                                                                     toURL:[self storeURL_Local]
                                                                   options:localStoreOptions
                                                                  withType:NSSQLiteStoreType error:nil];
        
        if (newStore) {
            NSString* tokenString = [[NSKeyedArchiver archivedDataWithRootObject:[self ubiquityIdentityToken]] base64Encoding];
            NSString* Setting_MigrationFromCloudPerformed = [NSString stringWithFormat:Setting_MigrationFromCloudPerformedBase, tokenString];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:Setting_MigrationFromCloudPerformed];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString* msgTitle = NSLocalizedStringFromTableInBundle(@"iCloud.MigrationFromCloudFailed.Title", @"ICL_iCloud", [NSBundle localisationBundle], @"iCloud Migration Failed");
                NSString* msgBody = NSLocalizedStringFromTableInBundle(@"iCloud.MigrationFromCloudFailed.Body", @"ICL_iCloud", [NSBundle localisationBundle], @"Migration of the data to iCloud failed. Local data will be used instead.");
                
                UIAlertView* warning = [[UIAlertView alloc] initWithTitle:msgTitle message:msgBody delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"ok", @"ICL_Common", [NSBundle localisationBundle], @"Ok") otherButtonTitles:nil];
                
                if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                }
                
                [warning show];
            });
        }
        
        [self switchStoreToLocal];
        
        self.currentState = essReadyToLoadStore;
        
        [self requestLoadDataStore];
    }];
}

#pragma mark Notification Registration

- (void)CoreData_RegisterForNotifications:(NSPersistentStoreCoordinator*) coordinator {
    NSNotificationCenter* notificationCentre = [NSNotificationCenter defaultCenter];
    
    if (Using_iOS7OrAbove) {
        [notificationCentre addObserver:self
                               selector:@selector(CoreData_StoresWillChange:)
                                   name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                 object:coordinator];
    }
    
    [notificationCentre addObserver:self
                           selector:@selector(CoreData_StoresDidChange:)
                               name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                             object:coordinator];
    
    [notificationCentre addObserver:self
                           selector:@selector(CoreData_StoreDidImportUbiquitousContentChanges:)
                               name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                             object:coordinator];
}

- (void)CoreData_UnregisterForNotifications {
    NSNotificationCenter* notificationCentre = [NSNotificationCenter defaultCenter];
    
    if (Using_iOS7OrAbove) {
        [notificationCentre removeObserver:self
                                      name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                    object:self.persistentStoreCoordinator];
    }
    [notificationCentre removeObserver:self
                                  name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                object:self.persistentStoreCoordinator];
    [notificationCentre removeObserver:self
                                  name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                object:self.persistentStoreCoordinator];
}

#pragma mark Notification Handlers

- (void) iCloudAccountChanged:(NSNotification*) notification {
    // already processing an account changed notification
    if (_accountChanged) {
        return;
    }
    
    // ignore iCloud account changes if the user has selected not to use iCloud
    if (![[NSUserDefaults standardUserDefaults] boolForKey:Setting_iCloudEnabled]) {
        return;
    }
    
    // If the iCloud account changes then the device list path will be invalid.
    // Force it to update by tearing it down and recreating it.
    
    [self teardownDeviceList];
    
    [self setupDeviceList];
    
    BOOL iCloudExistsNow = [self iCloudAvailable];
    
    // If no previous identity token was stored then there will be no store changed notification.
    // Manually send it to trigger the refresh of the UI and the data.
    if (iCloudExistsNow) {
        _accountChanged = YES;
        
        [self CoreData_StoresWillChange:nil];
        
        if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        }
        
        self.currentState = essUninitialised;
        self.requestFinishLoadingDataStoreReceived = YES;
        
        [self requestLoadDataStore];
    }
}

- (void)CoreData_StoresWillChange:(NSNotification*) notification {
    // migrations should ignore all notifications
    if ((self.currentState == essMigrateCloudDataToLocal) || (self.currentState == essMigrateLocalDataToCloud)) {
        return;
    }
    
//    BOOL dataStoreIsFullyReady = NO;
//    
//    NSDictionary* userInfo = notification.userInfo;
//    if (userInfo[NSPersistentStoreUbiquitousTransitionTypeKey]) {
//        NSPersistentStoreUbiquitousTransitionType transitionType = (NSPersistentStoreUbiquitousTransitionType)[userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] integerValue];
//        
//        dataStoreIsFullyReady = transitionType == NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted;
//    }
    
    NSManagedObjectContext *context = self.managedObjectContext;
    
    [ICLCoreDataManagerInstance performBlockAndWait:^{
        NSError *error = nil;
        
        [self abandonUndoGroups];
        
        if ([context hasChanges]) {
            [context save:&error];
        }
        
        [context reset];
    }];
    
    void(^willChangeblock)() = ^() {
        [self.delegate storeWillChangeNotification];
        
        if (!_accountChanged) {
            self.currentState = essReadyToLoadStore;
        }
    };
    
    if ([NSThread currentThread].isMainThread) {
        willChangeblock();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), willChangeblock);
    }
}

- (void)CoreData_StoresDidChange:(NSNotification*) notification {
    // migrations should ignore all notifications
    if ((self.currentState == essMigrateCloudDataToLocal) || (self.currentState == essMigrateLocalDataToCloud)) {
        return;
    }
    
//    BOOL dataStoreIsFullyReady = NO;
//    
//    NSDictionary* userInfo = notification.userInfo;
//    if (userInfo[NSPersistentStoreUbiquitousTransitionTypeKey]) {
//        NSPersistentStoreUbiquitousTransitionType transitionType = (NSPersistentStoreUbiquitousTransitionType)[userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] integerValue];
//        
//        dataStoreIsFullyReady = transitionType == NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted;
//    }
    
    // iOS 6 and below do not support the StoresWillChange notification
    if (!Using_iOS7OrAbove) {
        [self CoreData_StoresWillChange:nil];
    }
    
    // if the account has not changed then we can proceed with a minimal reload
    if (!_accountChanged) {
        self.currentState = essDataStoreOnline;
        
        BOOL iCloudPreviouslyExisted = [[NSUserDefaults standardUserDefaults] objectForKey:Setting_IdentityToken] != nil;
        BOOL iCloudExistsNow = [self iCloudAvailable];
        
        if (iCloudPreviouslyExisted && !iCloudExistsNow) {
            [self forceLocalStoreAndDisableiCloud];
            [self managedObjectContext];
        }
        
        void(^didChangeBlock)() = ^() {
            [self.delegate storeDidChangeNotification];
        };
        
        if ([NSThread currentThread].isMainThread) {
            didChangeBlock();
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), didChangeBlock);
        }
        
        // listen for iCloud account changes
        if (_firstTimeOnline) {
            _firstTimeOnline = NO;
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(iCloudAccountChanged:)
                                                         name:NSUbiquityIdentityDidChangeNotification
                                                       object:nil];
        }
    }
}

- (void)CoreData_StoreDidImportUbiquitousContentChanges:(NSNotification*) notification {
    NSManagedObjectContext* context = self.managedObjectContext;
    
    [ICLCoreDataManagerInstance performBlock:^{
        [self abandonUndoGroups];
        
        [context mergeChangesFromContextDidSaveNotification:notification];
        
        void(^didImportBlock)() = ^() {
            [self.delegate storeDidImportUbiquitousContentChangesNotification:notification];
        };
        
        if ([NSThread currentThread].isMainThread) {
            didImportBlock();
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), didImportBlock);
        }
    }];
}

#pragma mark Undo Handling

- (void) beginUndoGroup {
    @synchronized(self) {
        self.undoLevel = @([self.undoLevel integerValue] + 1);
        [self.managedObjectContext.undoManager beginUndoGrouping];
    }
}

- (void) endUndoGroup:(BOOL) applyUndo {
    @synchronized(self) {
        self.undoLevel = @([self.undoLevel integerValue] - 1);
        
        [self.managedObjectContext.undoManager endUndoGrouping];
        
        if (applyUndo) {
            [self.managedObjectContext.undoManager undoNestedGroup];
        }
    }
}

- (void) abandonUndoGroups {
    @synchronized(self) {
        while  ([self.undoLevel integerValue] > 0) {
            [self endUndoGroup:NO];
        }
    }
}

@end
