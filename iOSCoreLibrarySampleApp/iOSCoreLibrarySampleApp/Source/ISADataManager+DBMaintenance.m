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
