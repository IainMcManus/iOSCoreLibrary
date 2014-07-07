//
//  ICLCoreDataDeviceList.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 5/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLCoreDataDeviceList.h"
#import "ICLCoreDataManager.h"

@implementation ICLCoreDataDeviceList {
    NSURL* _deviceListURL;
    NSOperationQueue* _operationQueue;
}

- (id) initWithURLAndQueue:(NSURL*) fileURL queue:(NSOperationQueue*) queue {
    if ((self = [super init])) {
        _deviceListURL = fileURL;
        _operationQueue = queue;
    }
    
    return self;
}

- (NSURL*) presentedItemURL {
    return _deviceListURL;
}

- (NSOperationQueue*) presentedItemOperationQueue {
    return _operationQueue;
}

- (void) presentedItemDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ICLCoreDataManager Instance] deviceListChanged:nil];
    });
}

- (void) accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ICLCoreDataManager Instance] deviceListChanged:nil];
    });
    
    completionHandler(nil);
}

@end
