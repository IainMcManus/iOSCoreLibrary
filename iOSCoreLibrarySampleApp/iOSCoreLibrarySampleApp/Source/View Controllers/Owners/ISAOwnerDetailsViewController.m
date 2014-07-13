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

@interface ISAOwnerDetailsViewController () <StoreChangedDelegate>

@end

@implementation ISAOwnerDetailsViewController

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
    }
    else {
        [self.ownerName setText:@""];
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
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[ISADataManager Instance] unregisterStoreChangedDelegate:self];
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
}

- (void) storeDidChange {
}
@end
