//
//  Classification.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 10/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Pet;

@interface Classification : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSSet *pets;
@end

@interface Classification (CoreDataGeneratedAccessors)

- (void)addPetsObject:(Pet *)value;
- (void)removePetsObject:(Pet *)value;
- (void)addPets:(NSSet *)values;
- (void)removePets:(NSSet *)values;

@end
