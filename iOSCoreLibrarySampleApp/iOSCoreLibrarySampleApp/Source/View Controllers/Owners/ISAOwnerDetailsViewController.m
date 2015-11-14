//
//  ISAOwnerDetailsViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAOwnerDetailsViewController.h"

#import "Owner+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@interface ISAOwnerDetailsViewController () <StoreChangedDelegate, UIAlertViewDelegate, OwnerChangedDelegate>

@end

@implementation ISAOwnerDetailsViewController {
    UIAlertView* iCloudChangedAlert;
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
    
    if (self.owner) {
        [self.ownerName setText:self.owner.name];
        
        [self.titleItem setTitle:NSLocalizedStringFromTable(@"EditOwner", @"Owners", @"Edit Owner")];
    }
    else {
        [self.ownerName setText:@""];
        
        [self.titleItem setTitle:NSLocalizedStringFromTable(@"AddOwner", @"Owners", @"Add Owner")];
    }
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
    
    [[ISADataManager Instance] registerStoreChangedDelegate:self];
    [[ISADataManager Instance] registerOwnerChangedDelegate:self];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[ISADataManager Instance] unregisterStoreChangedDelegate:self];
    [[ISADataManager Instance] unregisterOwnerChangedDelegate:self];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    if ([self.ownerName.text length] > 0) {
        ICLCoreDataManager* dataManager = [ICLCoreDataManager Instance];
        
        Owner* owner = self.owner;
        
        if (!owner) {
            owner = [NSEntityDescription insertNewObjectForEntityForName:@"Owner"
                                                  inManagedObjectContext:[dataManager managedObjectContext]];
        }
        
        owner.name = self.ownerName.text;
        
        [dataManager saveContext];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"IncorrectName.Title", @"Errors", @"Incorrect Name")
                                    message:NSLocalizedStringFromTable(@"IncorrectName.Message", @"Errors", @"The name cannot be empty.")
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedStringFromTable(@"Ok", @"Common", @"Ok"), nil] show];
    }
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
    self.owner = nil;
}

- (void) storeDidChange {
    // StoreDidChange will typically NOT be called from the main thread.
    // As we need to display UI we must issue that block on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* messageTitle = NSLocalizedStringFromTable(@"StoreChanged.Title", @"iCloud", @"iCloud Database Changed");
        NSString* message = NSLocalizedStringFromTable(@"StoreChanged.Message", @"iCloud", @"The iCloud database has changed. You will be returned to the main screen.");
        
        iCloudChangedAlert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedStringFromTable(@"Ok", @"Common", @"Ok"), nil];
        iCloudChangedAlert.delegate = self;
        
        [iCloudChangedAlert show];
    });
}

#pragma mark UIAlertViewDelegate Support

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // All iCloud alerts dismiss the current view.
    if (alertView == iCloudChangedAlert) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma OwnerChangedDelegate support

- (void) ownerAdded:(Owner *)owner remoteChange:(BOOL)isRemoteChange {
    // Nothing to do in response to an add.
}

- (void) ownerDeleted:(Owner *)owner remoteChange:(BOOL)isRemoteChange {
    // We only care if the owner we are editing was deleted.
    if (self.owner && (self.owner == owner)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* messageTitle = NSLocalizedStringFromTable(@"Deleted.Title", @"Owners", @"Current Owner Deleted");
            NSString* message = NSLocalizedStringFromTable(@"Deleted.Message", @"Owners", @"The Owner you are editing was deleted remotely. You will be returned to the main screen.");
            
            iCloudChangedAlert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedStringFromTable(@"Ok", @"Common", @"Ok"), nil];
            iCloudChangedAlert.delegate = self;
            
            [iCloudChangedAlert show];
        });
    }
}

- (void) ownerUpdated:(Owner *)owner remoteChange:(BOOL)isRemoteChange {
    // We only care if the owner we are editing was updated.
    if (isRemoteChange && self.owner && (self.owner == owner)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* messageTitle = NSLocalizedStringFromTable(@"Modified.Title", @"Owners", @"Current Owner Modified");
            NSString* message = NSLocalizedStringFromTable(@"Modified.Message", @"Owners", @"The Owner you are editing was modified remotely. You will be returned to the main screen.");
            
            iCloudChangedAlert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedStringFromTable(@"Ok", @"Common", @"Ok"), nil];
            iCloudChangedAlert.delegate = self;
            
            [iCloudChangedAlert show];
        });
    }
}

@end
