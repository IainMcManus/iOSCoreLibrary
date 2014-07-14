//
//  ISASettingsTabViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 12/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISASettingsTabViewController.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>
#import <iOSCoreLibrary/UIButton+applyGlassStyle.h>

@interface ISASettingsTabViewController () <StoreChangedDelegate>

@end

@implementation ISASettingsTabViewController {
    BOOL iCloudEnabled;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ISADataManager Instance] registerStoreChangedDelegate:self];
    
    // set iCloudEnabled to the inverse so that it forces a refresh
    iCloudEnabled = ![[ICLCoreDataManager Instance] iCloudIsEnabled];
    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Notify that this view is now visible. This is used as part of handling new iCloud data being synchronised.
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_LoadedNewVC
                                                        object:nil
                                                      userInfo:@{@"viewController": self}];
}

- (IBAction)toggleiCloud:(id)sender {
    if ([[ICLCoreDataManager Instance] iCloudIsEnabled]) {
        [[ICLCoreDataManager Instance] toggleiCloud:NO];
    }
    else {
        [[ICLCoreDataManager Instance] toggleiCloud:YES];
    }
}

- (void) refresh {
    if ([[ICLCoreDataManager Instance] iCloudAvailable]) {
        [self.iCloudNotAvailableMessage setHidden:YES];
        [self.toggleiCloudButton setHidden:NO];
        
        BOOL newiCloudEnabled = [[ICLCoreDataManager Instance] iCloudIsEnabled];
        
        if (iCloudEnabled != newiCloudEnabled) {
            if (newiCloudEnabled) {
                [self.toggleiCloudButton setTitle:NSLocalizedStringFromTable(@"iCloud.Disable", @"iCloud", @"Disable iCloud")
                                         forState:UIControlStateNormal];
                
                [self.toggleiCloudButton applyGlassStyle:egbsSmall colour:[UIColor colorWithHue:0.0f/360.0f saturation:0.8f brightness:0.8f alpha:1.0f] autoColourText:YES];
            }
            else {
                [self.toggleiCloudButton setTitle:NSLocalizedStringFromTable(@"iCloud.Enable", @"iCloud", @"Enable iCloud")
                                         forState:UIControlStateNormal];
                
                [self.toggleiCloudButton applyGlassStyle:egbsSmall colour:[UIColor colorWithHue:120.0f/360.0f saturation:0.8f brightness:0.8f alpha:1.0f] autoColourText:YES];
            }
            
            iCloudEnabled = newiCloudEnabled;
        }
    }
    else {
        [self.iCloudNotAvailableMessage setHidden:NO];
        [self.toggleiCloudButton setHidden:YES];
    }
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
}

- (void) storeDidChange {
    [self refresh];
}

@end
