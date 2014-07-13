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

@interface ISAPetDetailsViewController () <StoreChangedDelegate, UITableViewDataSource, UITableViewDelegate>

@end

@implementation ISAPetDetailsViewController {
    NSArray* cachedClassifications;
    NSArray* cachedOwners;
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
        
        if (self.pet.classification) {
            NSUInteger classificationIndex = [cachedClassifications indexOfObject:self.pet.classification];
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:classificationIndex
                                                        inSection:0];
            [self.classificationsTable selectRowAtIndexPath:indexPath
                                                   animated:NO
                                             scrollPosition:UITableViewScrollPositionTop];
        }
        
        if (self.pet.owner) {
            NSUInteger ownerIndex = [cachedOwners indexOfObject:self.pet.owner];
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ownerIndex
                                                        inSection:0];
            [self.ownersTable selectRowAtIndexPath:indexPath
                                          animated:NO
                                    scrollPosition:UITableViewScrollPositionTop];
        }
    }
    else {
        [self.petName setText:@""];
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
            pet = [NSEntityDescription insertNewObjectForEntityForName:@"PEt"
                                                inManagedObjectContext:[dataManager managedObjectContext]];
        }
        
        pet.name = self.petName.text;
        
        NSIndexPath* selectedOwner = [self.ownersTable indexPathForSelectedRow];
        pet.owner = selectedOwner ? cachedOwners[selectedOwner.row] : nil;
        
        NSIndexPath* selectedClassification = [self.classificationsTable indexPathForSelectedRow];
        pet.classification = selectedClassification ? cachedClassifications[selectedClassification.row] : nil;
        
        [dataManager saveContext];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
}

- (void) storeDidChange {
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


- (UITableViewCellEditingStyle) tableView:(UITableView*) tableView editingStyleForRowAtIndexPath:(NSIndexPath*) indexPath {
    return UITableViewCellEditingStyleNone;
}

@end
