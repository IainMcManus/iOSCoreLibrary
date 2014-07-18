//
//  ISADataManager+DBMaintenance.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 11/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISADataManager+DBMaintenance.h"

#import "Pet+Extensions.h"
#import "Owner+Extensions.h"
#import "Classification+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@implementation ISADataManager (DBMaintenance)

- (void) deduplicate_Classifications:(NSManagedObjectContext*) context {
    NSMutableArray* purgeList = [[NSMutableArray alloc] init];
    
    NSArray* allClassifications = [Classification allObjects];
    
    // Extract an array of all the names with duplicates removed.
    NSArray* classificationNames = [allClassifications valueForKeyPath:@"@distinctUnionOfObjects.name"];
    
    // no duplicates - nothing to do
    if ([allClassifications count] == [classificationNames count]) {
        return;
    }
    
    NSSortDescriptor* creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    
    // Traverse the list of unique classification names and identify any duplicates
    for (NSString* classificationName in classificationNames) {
        NSArray* filteredObjects = [allClassifications filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", classificationName]];
        
        // no work if there are no duplicates for this name
        if ([filteredObjects count] <= 1) {
            continue;
        }
        
        filteredObjects = [filteredObjects sortedArrayUsingDescriptors:@[creationDateSort]];
        
        // The first object is considered the prime object (ie. the one to be kept).
        Classification* primeObject = [filteredObjects firstObject];
        
        for (Classification* classification in filteredObjects) {
            // skip the prime object
            if (classification == primeObject) {
                continue;
            }
            
            [classification remapAllReferencesTo:primeObject];
            [purgeList addObject:classification];
        }
    }
    
    if ([purgeList count] > 0) {
        NSLog(@"Purging %lu duplicate classifications", (unsigned long)[purgeList count]);
        for (NSManagedObject* object in purgeList) {
            [context deleteObject:object];
        }
    }
}

- (void) deduplicate_Owners:(NSManagedObjectContext*) context {
    NSMutableArray* purgeList = [[NSMutableArray alloc] init];
    
    NSArray* allOwners = [Owner allObjects];
    
    // Extract an array of all the names with duplicates removed.
    NSArray* ownerNames = [allOwners valueForKeyPath:@"@distinctUnionOfObjects.name"];
    
    // no duplicates - nothing to do
    if ([allOwners count] == [ownerNames count]) {
        return;
    }
    
    NSSortDescriptor* creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    
    // Traverse the list of unique owners names and identify any duplicates
    for (NSString* ownerName in ownerNames) {
        NSArray* filteredObjects = [allOwners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", ownerName]];
        
        // no work if there are no duplicates for this name
        if ([filteredObjects count] <= 1) {
            continue;
        }
        
        filteredObjects = [filteredObjects sortedArrayUsingDescriptors:@[creationDateSort]];
        
        // The first object is considered the prime object (ie. the one to be kept).
        Owner* primeObject = [filteredObjects firstObject];
        
        for (Owner* owner in filteredObjects) {
            // skip the prime object
            if (owner == primeObject) {
                continue;
            }
            
            [owner remapAllReferencesTo:primeObject];
            [purgeList addObject:owner];
        }
    }
    
    if ([purgeList count] > 0) {
        NSLog(@"Purging %lu duplicate owners", (unsigned long)[purgeList count]);
        for (NSManagedObject* object in purgeList) {
            [context deleteObject:object];
        }
    }
}

- (void) deduplicate_Pets:(NSManagedObjectContext*) context {
    NSMutableArray* purgeList = [[NSMutableArray alloc] init];
    
    NSArray* allPets = [Pet allObjects];
    
    // Extract an array of all the names with duplicates removed.
    NSArray* petFingerprints = [allPets valueForKeyPath:@"@distinctUnionOfObjects.fingerprint"];
    
    // no duplicates - nothing to do
    if ([allPets count] == [petFingerprints count]) {
        return;
    }
    
    NSSortDescriptor* creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    
    // Traverse the list of unique fingerprints and identify any duplicates
    for (NSNumber* fingerprint in petFingerprints) {
        NSArray* filteredObjects = [allPets filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"fingerprint = %@", fingerprint]];

        // no work if there are no duplicates for this name
        if ([filteredObjects count] <= 1) {
            continue;
        }

        filteredObjects = [filteredObjects sortedArrayUsingDescriptors:@[creationDateSort]];
        
        // The first object is considered the prime object (ie. the one to be kept).
        Pet* primeObject = [filteredObjects firstObject];
        
        for (Pet* pet in filteredObjects) {
            // skip the prime object
            if (pet == primeObject) {
                continue;
            }
            
            // no remapping required, we can simply delete
            
            [purgeList addObject:pet];
        }
    }
    
    if ([purgeList count] > 0) {
        NSLog(@"Purging %lu duplicate pets", (unsigned long)[purgeList count]);
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
        
        // Remove all duplicate owners and classifications first
        [self deduplicate_Classifications:context];
        [self deduplicate_Owners:context];
        
        // Finally deduplicate all pets
        [self deduplicate_Pets:context];
        
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
    
    // Only perform the import if there is no data present for any of the managed objects
    if (([[Pet allObjects] count] == 0) &&
        ([[Owner allObjects] count] == 0) &&
        ([[Classification allObjects] count] == 0)) {
        NSManagedObjectContext *context = [coreDataManager managedObjectContext];
        
        NSError* err = nil;
        
        // Import all of the classification data from the JSON file
        NSString* classificationsPath = [[NSBundle mainBundle] pathForResource:@"Classifications" ofType:@"json"];
        NSArray* classificationsToImport = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:classificationsPath]
                                                                           options:kNilOptions
                                                                             error:&err];
        for (NSDictionary* classification in classificationsToImport) {
            Classification* newClassification = [NSEntityDescription insertNewObjectForEntityForName:@"Classification"
                                                                              inManagedObjectContext:context];
            newClassification.name = classification[@"name"];
        }
        
        // Create a map of classification names to the objects
        NSArray* allClassifications = [Classification allObjects];
        NSArray* allClassificationNames = [allClassifications valueForKey:@"name"];
        NSDictionary* classificationNameMapping = [[NSDictionary alloc] initWithObjects:allClassifications
                                                                                forKeys:allClassificationNames];

        // Import all of the owner data from the JSON file
        NSString* ownersPath = [[NSBundle mainBundle] pathForResource:@"Owners" ofType:@"json"];
        NSArray* ownersToImport = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:ownersPath]
                                                                           options:kNilOptions
                                                                             error:&err];
        for (NSDictionary* owner in ownersToImport) {
            Owner* newOwner = [NSEntityDescription insertNewObjectForEntityForName:@"Owner"
                                                            inManagedObjectContext:context];
            newOwner.name = owner[@"name"];
        }

        // Create a map of owner names to the objects
        NSArray* allOwners = [Owner allObjects];
        NSArray* allOwnerNames = [allOwners valueForKey:@"name"];
        NSDictionary* ownerNameMapping = [[NSDictionary alloc] initWithObjects:allOwners
                                                                       forKeys:allOwnerNames];

        // Import all of the pet data from the JSON file
        NSString* petsPath = [[NSBundle mainBundle] pathForResource:@"Pets" ofType:@"json"];
        NSArray* petsToImport = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:petsPath]
                                                                           options:kNilOptions
                                                                             error:&err];
        for (NSDictionary* pet in petsToImport) {
            Pet* newPet = [NSEntityDescription insertNewObjectForEntityForName:@"Pet"
                                                        inManagedObjectContext:context];
            newPet.name = pet[@"name"];
            
            if (pet[@"owner"]) {
                newPet.owner = ownerNameMapping[pet[@"owner"]];
            }
            if (pet[@"classification"]) {
                newPet.classification = classificationNameMapping[pet[@"classification"]];
            }
        }
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        [[ICLCoreDataManager Instance] minimalDataImportWasPerformed];
    }
    
    [[[ICLCoreDataManager Instance] persistentStoreCoordinator] unlock];
}

@end
