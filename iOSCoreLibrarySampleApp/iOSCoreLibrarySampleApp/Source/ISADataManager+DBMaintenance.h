//
//  ISADataManager+DBMaintenance.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 11/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISADataManager.h"

@interface ISADataManager (DBMaintenance)

- (void) performDataDeduplication;
- (void) loadMinimalDataSetIfRequired;

@end
