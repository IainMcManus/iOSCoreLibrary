//
//  Pet.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 10/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Classification, Owner;

@interface Pet : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) Owner *owner;
@property (nonatomic, retain) Classification *classification;

@end
