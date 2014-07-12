//
//  ISAAppDelegate.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 10/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAAppDelegate.h"

#import "ISADataManager.h"

@implementation ISAAppDelegate

#if DEBUG
void uncaughtExceptionHandler(NSException* exception) {
    NSString* documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy_HH_mm"];
    
    NSString* reportFileName = [NSString stringWithFormat:@"Crash_%@.txt", [dateFormatter stringFromDate:[NSDate date]]];
    NSString* crashReport = [documentsDirectory stringByAppendingPathComponent:reportFileName];
    NSLog(@"%@", crashReport);
    
    NSMutableString* reportContents = [[NSMutableString alloc] init];
    [reportContents appendString:@"Injaia Crash Report File\r\n"];
    [reportContents appendString:@"\r\n"];
    
    [reportContents appendString:[NSString stringWithFormat:@"Reason: %@\r\n", [exception reason]]];
    [reportContents appendString:@"\r\n"];
    
    [reportContents appendString:@"Callstack:\r\n"];
    for (NSString* entry in [exception callStackSymbols]) {
        [reportContents appendString:[NSString stringWithFormat:@"    %@\r\n", entry]];
    }
    
    [reportContents writeToFile:crashReport atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}
#endif // DEBUG

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
#endif // DEBUG
    
    [[ISADataManager Instance] applicationInitialised];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
