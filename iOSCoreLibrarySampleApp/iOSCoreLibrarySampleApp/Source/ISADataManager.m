//
//  ISADataManager.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 11/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISADataManager.h"
#import "ISADataManager+DBMaintenance.h"

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
    UIViewController* _currentViewController;
}

- (id) initInstance {
    if ((self = [super init])) {
        Colour_AlertView_Button1 = [UIColor colorWithHue:220.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
        Colour_AlertView_Button2 = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
        Colour_AlertView_Panel1 = [UIColor colorWithHue:210.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
        Colour_AlertView_Panel2 = [UIColor colorWithHue:110.0f/360.0f saturation:0.5f brightness:1.0f alpha:0.25f];
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
#if DEBUG
    //    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    //    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
    //    [[NSUserDefaults standardUserDefaults] synchronize];
#endif // DEBUG
    
    [ICLCoreDataManager Instance].delegate = self;
    
    [ICLCoreDataManager Instance].Colour_AlertView_Button1 = Colour_AlertView_Button1;
    [ICLCoreDataManager Instance].Colour_AlertView_Button2 = Colour_AlertView_Button2;
    [ICLCoreDataManager Instance].Colour_AlertView_Panel1 = Colour_AlertView_Panel1;
    [ICLCoreDataManager Instance].Colour_AlertView_Panel2 = Colour_AlertView_Panel2;
    
    _StoreChangedDelegates = [[NSMutableArray alloc] init];
    
    _currentViewController = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadedNewVC:) name:Notification_LoadedNewVC object:nil];
    
    [[ICLCoreDataManager Instance] requestBeginLoadingDataStore];
}

- (void)loadedNewVC:(NSNotification *) notification {
    if([notification userInfo][@"viewController"]) {
        // if this is the first view we have become aware of then the UI is ready and we can finish loading the data
        if (!_currentViewController) {
            [[ICLCoreDataManager Instance] requestFinishLoadingDataStore];
        }
        
        _currentViewController = [notification userInfo][@"viewController"];
    }
}

- (UIViewController*) currentViewController {
    return _currentViewController;
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
//    NSManagedObjectContext* context = [[ICLCoreDataManager Instance] managedObjectContext];
    
    [self performDataDeduplication];
    
//    NSDictionary* changes = notification.userInfo;

//    for (NSManagedObjectID* deletedObjectId in changes[NSDeletedObjectsKey]) {
//        NSManagedObject* deletedObject = [context existingObjectWithID:deletedObjectId error:nil];
//    }
//    for (NSManagedObjectID* addedObjectId in changes[NSInsertedObjectsKey]) {
//        NSManagedObject* addedObject = [context existingObjectWithID:addedObjectId error:nil];
//    }
//    for (NSManagedObjectID* updatedObjectId in changes[NSUpdatedObjectsKey]) {
//        NSManagedObject* updatedObject = [context existingObjectWithID:updatedObjectId error:nil];
//    }
}

- (void) eventStoreWillChange {
    if (![[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    
    for (id eventHandler in self.StoreChangedDelegates) {
        [eventHandler storeWillChange];
    }
}

- (void) eventStoreDidChange {
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
    
    if (_currentViewController && ![_currentViewController conformsToProtocol:@protocol(StoreChangedDelegate)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            UIViewController* viewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainView"];
            
            id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
            appDelegate.window.rootViewController = viewController;
            [appDelegate.window makeKeyAndVisible];
            
            [self.StoreChangedDelegates removeAllObjects];
        });
    }
    else {
        for (id eventHandler in self.StoreChangedDelegates) {
            [eventHandler storeDidChange];
        }
    }
}

- (void) registerStoreChangedDelegate:(id) inHandler {
    [self.StoreChangedDelegates addObject:inHandler];
}

- (void) unregisterStoreChangedDelegate:(id) inHandler {
    [self.StoreChangedDelegates removeObject:inHandler];
}

@end
