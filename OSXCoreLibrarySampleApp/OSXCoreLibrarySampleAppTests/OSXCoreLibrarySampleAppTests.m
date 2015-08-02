//
//  OSXCoreLibrarySampleAppTests.m
//  OSXCoreLibrarySampleAppTests
//
//  Created by Iain McManus on 2/08/2015.
//  Copyright (c) 2015 Injaia. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

@interface OSXCoreLibrarySampleAppTests : XCTestCase

@end

@implementation OSXCoreLibrarySampleAppTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
