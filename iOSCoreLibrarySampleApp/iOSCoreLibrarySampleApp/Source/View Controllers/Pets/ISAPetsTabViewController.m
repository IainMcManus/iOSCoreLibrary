//
//  ISAPetsTabViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 12/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAPetsTabViewController.h"

#import "Pet+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@interface ISAPetsTabViewController () <StoreChangedDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@end

@implementation ISAPetsTabViewController {
    NSArray* cachedPets;
    
    Pet* petToDelete;
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
    
    [self refreshDisplay];
}

- (void) refreshDisplay {
    cachedPets = [Pet allObjects];
    [self.petsTable reloadData];
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
}

- (void) storeDidChange {
}

#pragma mark UITableViewDataSource Support

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cachedPets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PetCell"];
    Pet* petForCell = cachedPets[indexPath.row];
    
    [cell.textLabel setText:petForCell.name];
    
    return cell;
}

- (void) tableView:(UITableView*) tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath*) indexPath {
    NSString* messageTitle = NSLocalizedStringFromTable(@"Delete.ConfirmationMessageTitle", @"Common", @"Confirm Deletion");
    NSString* message = nil;
    
    petToDelete = cachedPets[indexPath.row];
    
    message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"DeletePet", @"Pets", @"Are you sure you wish to delete the pet %@ ?"), petToDelete.name];
    
    deleteConfirmation = [[UIAlertView alloc] initWithTitle:messageTitle message:message delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"no", @"Common", @"No") otherButtonTitles:NSLocalizedStringFromTable(@"yes", @"Common", @"Yes"), nil];
    
    [deleteConfirmation show];
}

#pragma mark UITableViewDelegate Support

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"EditPet" sender:cachedPets[indexPath.row]];
}

- (UITableViewCellEditingStyle) tableView:(UITableView*) tableView editingStyleForRowAtIndexPath:(NSIndexPath*) indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark UIAlertViewDelegate Support

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex {
    if (alertView == deleteConfirmation) {
        if (buttonIndex == 0) {
            petToDelete = nil;
        }
        else {
            NSManagedObjectContext* context = [[ICLCoreDataManager Instance] managedObjectContext];
            [context performBlockAndWait:^{
                [context deleteObject:petToDelete];
            }];
            [[ICLCoreDataManager Instance] saveContext];
            
            petToDelete = nil;
            
            [self refreshDisplay];
        }
    }
}

@end
