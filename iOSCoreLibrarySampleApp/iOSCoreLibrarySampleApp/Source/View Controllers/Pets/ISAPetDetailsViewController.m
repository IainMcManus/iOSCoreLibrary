//
//  ISAPetDetailsViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAPetDetailsViewController.h"

#import "Pet+Extensions.h"
#import "Classification+Extensions.h"
#import "Owner+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@interface ISAPetDetailsViewController () <StoreChangedDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, PetChangedDelegate, OwnerChangedDelegate, ClassificationChangedDelegate, DataChangedDelegate>

@end

@implementation ISAPetDetailsViewController {
    NSArray* cachedClassifications;
    NSArray* cachedOwners;
    
    Classification* selectedClassification;
    Owner* selectedOwner;
    
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
    
    cachedClassifications = [Classification allObjects];
    cachedOwners = [Owner allObjects];
    
    if (self.pet) {
        [self.petName setText:self.pet.name];
        
        selectedClassification = self.pet.classification;
        selectedOwner = self.pet.owner;
        
        if (selectedClassification) {
            NSUInteger classificationIndex = [cachedClassifications indexOfObject:self.pet.classification];
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:classificationIndex
                                                        inSection:0];
            [self.classificationsTable selectRowAtIndexPath:indexPath
                                                   animated:NO
                                             scrollPosition:UITableViewScrollPositionTop];
        }
        
        if (selectedOwner) {
            NSUInteger ownerIndex = [cachedOwners indexOfObject:self.pet.owner];
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ownerIndex
                                                        inSection:0];
            [self.ownersTable selectRowAtIndexPath:indexPath
                                          animated:NO
                                    scrollPosition:UITableViewScrollPositionTop];
        }
        
        [self.titleItem setTitle:NSLocalizedStringFromTable(@"EditPet", @"Pets", @"Edit Pet")];
    }
    else {
        [self.petName setText:@""];
        
        selectedClassification = nil;
        selectedOwner = nil;
        
        [self.titleItem setTitle:NSLocalizedStringFromTable(@"AddPet", @"Pets", @"Add Pet")];
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
    [[ISADataManager Instance] registerPetChangedDelegate:self];
    [[ISADataManager Instance] registerOwnerChangedDelegate:self];
    [[ISADataManager Instance] registerClassificationChangedDelegate:self];
    [[ISADataManager Instance] registerDataChangedDelegate:self];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[ISADataManager Instance] unregisterStoreChangedDelegate:self];
    [[ISADataManager Instance] unregisterPetChangedDelegate:self];
    [[ISADataManager Instance] unregisterOwnerChangedDelegate:self];
    [[ISADataManager Instance] unregisterClassificationChangedDelegate:self];
    [[ISADataManager Instance] unregisterDataChangedDelegate:self];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    if ([self.petName.text length] == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"IncorrectName.Title", @"Errors", @"Incorrect Name")
                                    message:NSLocalizedStringFromTable(@"IncorrectName.Message", @"Errors", @"The name cannot be empty.")
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedStringFromTable(@"Ok", @"Common", @"Ok"), nil] show];
    }
    else {
        ICLCoreDataManager* dataManager = [ICLCoreDataManager Instance];
        
        Pet* pet = self.pet;
        
        if (!pet) {
            pet = [NSEntityDescription insertNewObjectForEntityForName:@"Pet"
                                                inManagedObjectContext:[dataManager managedObjectContext]];
        }
        
        pet.name = self.petName.text;
        
        pet.owner = selectedOwner;
        pet.classification = selectedClassification;
        
        [dataManager saveContext];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
    self.pet = nil;
    cachedOwners = nil;
    cachedClassifications = nil;
    selectedOwner = nil;
    selectedClassification = nil;
}

- (void) storeDidChange {
    // StoreDidChange will typically NOT be called from the main thread.
    // As we need to display UI we must issue that block on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        iCloudChangedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"StoreChanged.Title", @"iCloud", @"iCloud Database Changed")
                                                        message:NSLocalizedStringFromTable(@"StoreChanged.Message", @"iCloud", @"The iCloud database has changed. You will be returned to the main screen.")
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

#pragma mark UITableViewDataSource Support

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.ownersTable) {
        return [cachedOwners count];
    }
    else if (tableView == self.classificationsTable) {
        return [cachedClassifications count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = nil;
    
    if (tableView == self.ownersTable) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"OwnerCell"];
        Owner* ownerForCell = cachedOwners[indexPath.row];
        
        [cell.textLabel setText:ownerForCell.name];
    }
    else if (tableView == self.classificationsTable) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ClassificationCell"];
        Classification* classificationForCell = cachedClassifications[indexPath.row];
        
        [cell.textLabel setText:classificationForCell.name];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate Support

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.classificationsTable) {
        selectedClassification = cachedClassifications[indexPath.row];
    }
    else if (tableView == self.ownersTable) {
        selectedOwner = cachedOwners[indexPath.row];
    }
}

- (UITableViewCellEditingStyle) tableView:(UITableView*) tableView editingStyleForRowAtIndexPath:(NSIndexPath*) indexPath {
    return UITableViewCellEditingStyleNone;
}

#pragma PetChangedDelegate support

- (void) petAdded:(Pet *)pet remoteChange:(BOOL)isRemoteChange {
    // Nothing to do in response to an add.
}

- (void) petDeleted:(Pet *)pet remoteChange:(BOOL)isRemoteChange {
    // We only care if the pet we are editing was deleted.
    if (self.pet && (self.pet == pet)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* messageTitle = NSLocalizedStringFromTable(@"Deleted.Title", @"Pets", @"Current Pet Deleted");
            NSString* message = NSLocalizedStringFromTable(@"Deleted.Message", @"Pets", @"The Pet you are editing was deleted remotely. You will be returned to the main screen.");
            
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

- (void) petUpdated:(Pet *)pet remoteChange:(BOOL)isRemoteChange {
    // We only care if the pet we are editing was updated.
    if (self.pet && (self.pet == pet)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* messageTitle = NSLocalizedStringFromTable(@"Modified.Title", @"Pets", @"Current Pet Modified");
            NSString* message = NSLocalizedStringFromTable(@"Modified.Message", @"Pets", @"The Pet you are editing was modified remotely. You will be returned to the main screen.");
            
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

#pragma DataChangedDelegate support

- (void) dataChanged:(NSDictionary *)changeInfo remoteChange:(BOOL)isRemoteChange {
    // Has a change to classifications happened?
    if (changeInfo[@(emtClassification)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshClassificationTable];
        });
    }
    
    // Has a change to owners happened?
    if (changeInfo[@(emtOwner)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshOwnerTable];
        });
    }
}

#pragma ClassificationChangedDelegate support

- (void) classificationAdded:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
}

- (void) classificationDeleted:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // if the selected classification was deleted then clear it
    if (selectedClassification == classification) {
        selectedClassification = nil;
    }
}

- (void) classificationUpdated:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
}

- (void) refreshClassificationTable {
    cachedClassifications = [Classification allObjects];
    [self.classificationsTable reloadData];
    
    if (selectedClassification) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[cachedClassifications indexOfObject:selectedClassification]
                                                    inSection:0];
        [self.classificationsTable selectRowAtIndexPath:indexPath
                                               animated:NO
                                         scrollPosition:UITableViewScrollPositionTop];
    }
}

#pragma OwnerChangedDelegate support

- (void) ownerAdded:(Owner *)owner remoteChange:(BOOL)isRemoteChange {
}

- (void) ownerDeleted:(Owner *)owner remoteChange:(BOOL)isRemoteChange {
    // if the selected owner was deleted then clear it
    if (selectedOwner == owner) {
        selectedOwner = nil;
    }
}

- (void) ownerUpdated:(Owner *)owner remoteChange:(BOOL)isRemoteChange {
}

- (void) refreshOwnerTable {
    cachedOwners = [Owner allObjects];
    [self.ownersTable reloadData];
    
    if (selectedOwner) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[cachedOwners indexOfObject:selectedOwner]
                                                    inSection:0];
        [self.ownersTable selectRowAtIndexPath:indexPath
                                      animated:NO
                                scrollPosition:UITableViewScrollPositionTop];
    }
}

@end
