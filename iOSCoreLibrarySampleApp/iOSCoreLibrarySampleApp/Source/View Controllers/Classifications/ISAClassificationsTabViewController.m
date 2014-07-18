//
//  ISAClassificationsTabViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 12/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAClassificationsTabViewController.h"
#import "ISAClassificationDetailsViewController.h"

#import "Classification+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@interface ISAClassificationsTabViewController () <StoreChangedDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, ClassificationChangedDelegate>

@end

@implementation ISAClassificationsTabViewController {
    NSArray* cachedClassifications;
    
    Classification* classificationToDelete;
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
    [[ISADataManager Instance] registerClassificationChangedDelegate:self];
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
    cachedClassifications = [Classification allObjects];
    [self.classificationsTable reloadData];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddClassification"]) {
        ISAClassificationDetailsViewController* viewController = [segue destinationViewController];
        viewController.classification = nil;
    }
    else if ([[segue identifier] isEqualToString:@"EditClassification"]) {
        ISAClassificationDetailsViewController* viewController = [segue destinationViewController];
        viewController.classification = sender;
    }
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
    // The objects are going away so clear out any stored data
    cachedClassifications = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.classificationsTable reloadData];
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
    return [cachedClassifications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ClassificationCell"];
    Classification* classificationForCell = cachedClassifications[indexPath.row];
    
    [cell.textLabel setText:classificationForCell.name];
    
    return cell;
}

- (void) tableView:(UITableView*) tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath*) indexPath {
    NSString* messageTitle = NSLocalizedStringFromTable(@"Delete.ConfirmationMessageTitle", @"Common", @"Confirm Deletion");
    NSString* message = nil;
    
    classificationToDelete = cachedClassifications[indexPath.row];
    
    message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"DeleteClassification", @"Classifications", @"Are you sure you wish to delete the classification %@ ?"), classificationToDelete.name];
    
    deleteConfirmation = [[UIAlertView alloc] initWithTitle:messageTitle message:message delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"no", @"Common", @"No") otherButtonTitles:NSLocalizedStringFromTable(@"yes", @"Common", @"Yes"), nil];
    
    [deleteConfirmation show];
}

#pragma mark UITableViewDelegate Support

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"EditClassification" sender:cachedClassifications[indexPath.row]];
}

- (UITableViewCellEditingStyle) tableView:(UITableView*) tableView editingStyleForRowAtIndexPath:(NSIndexPath*) indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark UIAlertViewDelegate Support

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex {
    if (alertView == deleteConfirmation) {
        if (buttonIndex == 0) {
            classificationToDelete = nil;
        }
        else {
            NSManagedObjectContext* context = [[ICLCoreDataManager Instance] managedObjectContext];
            [context performBlockAndWait:^{
                [context deleteObject:classificationToDelete];
            }];
            [[ICLCoreDataManager Instance] saveContext];
            
            classificationToDelete = nil;
            
            [self refreshDisplay];
        }
    }
}

#pragma ClassificationChangedDelegate support

- (void) classificationAdded:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // Nothing fancy is required. If we are the active VC then refresh the data. Otherwise it will be refreshed when we appear.
    if ([[ISADataManager Instance] currentViewController] == self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshDisplay];
        });
    }
}

- (void) classificationDeleted:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // Nothing fancy is required. If we are the active VC then refresh the data. Otherwise it will be refreshed when we appear.
    if ([[ISADataManager Instance] currentViewController] == self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshDisplay];
        });
    }
}

- (void) classificationUpdated:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // Nothing fancy is required. If we are the active VC then refresh the data. Otherwise it will be refreshed when we appear.
    if ([[ISADataManager Instance] currentViewController] == self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshDisplay];
        });
    }
}

@end
