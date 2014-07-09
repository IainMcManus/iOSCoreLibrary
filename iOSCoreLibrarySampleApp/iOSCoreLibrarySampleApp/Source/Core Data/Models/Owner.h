//
//  Owner.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 10/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Pet;

@interface Owner : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *pets;
@end

@interface Owner (CoreDataGeneratedAccessors)

- (void)addPetsObject:(Pet *)value;
- (void)removePetsObject:(Pet *)value;
- (void)addPets:(NSSet *)values;
- (void)removePets:(NSSet *)values;

@end
