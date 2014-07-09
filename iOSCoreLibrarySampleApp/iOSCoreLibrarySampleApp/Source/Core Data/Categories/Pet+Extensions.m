//
//  Pet+Extensions.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 10/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "Pet+Extensions.h"

@implementation Pet (Extensions)

- (void) awakeFromInsert {
    [super awakeFromInsert];
    
    self.creationDate = [NSDate date];
}

@end
