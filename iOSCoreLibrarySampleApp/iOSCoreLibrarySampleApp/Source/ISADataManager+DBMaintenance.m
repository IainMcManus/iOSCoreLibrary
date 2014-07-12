//
//  ISADataManager+DBMaintenance.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 11/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISADataManager+DBMaintenance.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@implementation ISADataManager (DBMaintenance)

- (void) purgeInvalidData:(NSManagedObjectContext*) context {
    NSMutableArray* purgeList = [[NSMutableArray alloc] init];
    
    // TODO
    
    if ([purgeList count] > 0) {
        NSLog(@"Purging %lu invalid objects", (unsigned long)[purgeList count]);
        for (NSManagedObject* object in purgeList) {
            [context deleteObject:object];
        }
    }
}


- (void) performDataDeduplication {
    NSLog(@"Beginning deduplication pass");
#if DEBUG
    NSDate* startDate = [NSDate date];
#endif // DEBUG
    
    NSManagedObjectContext *context = [[ICLCoreDataManager Instance] managedObjectContext];
    
    [context performBlockAndWait:^{
        if (context.undoManager) {
            [context.undoManager disableUndoRegistration];
        }
        
        [self purgeInvalidData:context];
        
        // TODO
        
        [[ICLCoreDataManager Instance] saveContext];
        
        if (context.undoManager) {
            [context.undoManager enableUndoRegistration];
        }
    }];
    
#if DEBUG
    NSDate* endDate = [NSDate date];
    NSLog(@"Deduplication took %lf seconds", [endDate timeIntervalSinceDate:startDate]);
#endif // DEBUG
}

- (void) loadMinimalDataSetIfRequired {
    ICLCoreDataManager* coreDataManager = [ICLCoreDataManager Instance];
    
    [[coreDataManager persistentStoreCoordinator] lock];
    
    if (0) {
        NSManagedObjectContext *context = [coreDataManager managedObjectContext];
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        [[ICLCoreDataManager Instance] minimalDataImportWasPerformed];
    }
    
    [[[ICLCoreDataManager Instance] persistentStoreCoordinator] unlock];
}

@end
