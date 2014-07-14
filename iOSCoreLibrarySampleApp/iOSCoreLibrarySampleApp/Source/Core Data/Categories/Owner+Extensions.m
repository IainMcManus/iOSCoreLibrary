//
//  Owner+Extensions.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 10/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "Owner+Extensions.h"
#import "Pet+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@implementation Owner (Extensions)

- (void) awakeFromInsert {
    [super awakeFromInsert];
    
    self.creationDate = [NSDate date];
}

+ (NSArray*) allObjects {
    NSManagedObjectContext* context = [[ICLCoreDataManager Instance] managedObjectContext];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Owner" inManagedObjectContext:context];
    
    [fetchRequest setEntity:entity];
    
    __block NSArray* results = nil;
    [context performBlockAndWait:^{
        results = [context executeFetchRequest:fetchRequest error:nil];
    }];
    
    return results;
}

- (void) remapAllReferencesTo:(Owner*) primeObject {
    // Switch all pets referencing this object to use the prime object
    NSArray* linkedPets = [self.pets allObjects];
    for (Pet* pet in linkedPets) {
        pet.owner = primeObject;
    }
}

- (NSNumber*) fingerprint {
    NSUInteger prime = 31;
    NSUInteger hash = 1;
    
    hash = prime * hash + [self.name hash];
    
    return @(hash);
}

@end
