//
//  ISAOwnersTabViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 12/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAOwnersTabViewController.h"
#import "ISAOwnerDetailsViewController.h"

#import "Owner+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@interface ISAOwnersTabViewController () <StoreChangedDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, DataChangedDelegate>

@end

@implementation ISAOwnersTabViewController {
    NSArray* cachedOwners;
    
    Owner* ownerToDelete;
    UIAlertView* deleteConfirmation;
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
    [[ISADataManager Instance] registerDataChangedDelegate:self];
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
    
    if ([[ICLCoreDataManager Instance] isDataStoreOnline]) {
        [self refreshDisplay];
    }
}

- (void) refreshDisplay {
    cachedOwners = [Owner allObjects];
    [self.ownersTable reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddOwner"]) {
        ISAOwnerDetailsViewController* viewController = [segue destinationViewController];
        viewController.owner = nil;
    }
    else if ([[segue identifier] isEqualToString:@"EditOwner"]) {
        ISAOwnerDetailsViewController* viewController = [segue destinationViewController];
        viewController.owner = sender;
    }
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
    // The objects are going away so clear out any stored data
    cachedOwners = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ownersTable reloadData];
    });
}

- (void) storeDidChange {
    // If we are the active VC then refresh the data. Otherwise it will be refreshed when we appear.
    if ([[ISADataManager Instance] currentViewController] == self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshDisplay];
        });
    }
}

#pragma mark UITableViewDataSource Support

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cachedOwners count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"OwnerCell"];
    Owner* ownerForCell = cachedOwners[indexPath.row];
    
    [cell.textLabel setText:ownerForCell.name];
    
    return cell;
}

- (void) tableView:(UITableView*) tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath*) indexPath {
    NSString* messageTitle = NSLocalizedStringFromTable(@"Delete.ConfirmationMessageTitle", @"Common", @"Confirm Deletion");
    NSString* message = nil;
    
    ownerToDelete = cachedOwners[indexPath.row];
    
    message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"DeleteOwner", @"Owners", @"Are you sure you wish to delete the owner %@ ?"), ownerToDelete.name];
    
    deleteConfirmation = [[UIAlertView alloc] initWithTitle:messageTitle message:message delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"no", @"Common", @"No") otherButtonTitles:NSLocalizedStringFromTable(@"yes", @"Common", @"Yes"), nil];
    
    [deleteConfirmation show];
}

#pragma mark UITableViewDelegate Support

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"EditOwner" sender:cachedOwners[indexPath.row]];
}

- (UITableViewCellEditingStyle) tableView:(UITableView*) tableView editingStyleForRowAtIndexPath:(NSIndexPath*) indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark UIAlertViewDelegate Support

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex {
    if (alertView == deleteConfirmation) {
        if (buttonIndex == 0) {
            ownerToDelete = nil;
        }
        else {
            NSManagedObjectContext* context = [[ICLCoreDataManager Instance] managedObjectContext];
            [context performBlockAndWait:^{
                [context deleteObject:ownerToDelete];
            }];
            [[ICLCoreDataManager Instance] saveContext];
            
            ownerToDelete = nil;
            
            [self refreshDisplay];
        }
    }
}

#pragma DataChangedDelegate support

- (void) dataChanged:(NSDictionary *)changeInfo remoteChange:(BOOL)isRemoteChange {
    // Has a change to owners happened?
    if (changeInfo[@(emtOwner)]) {
        // Nothing fancy is required. If we are the active VC then refresh the data. Otherwise it will be refreshed when we appear.
        if ([[ISADataManager Instance] currentViewController] == self) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshDisplay];
            });
        }
    }
}

@end
