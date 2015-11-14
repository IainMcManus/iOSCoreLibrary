//
//  ISAClassificationDetailsViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAClassificationDetailsViewController.h"

#import "Classification+Extensions.h"

#import <iOSCoreLibrary/ICLCoreDataManager.h>

@interface ISAClassificationDetailsViewController () <StoreChangedDelegate, UIAlertViewDelegate, ClassificationChangedDelegate>

@end

@implementation ISAClassificationDetailsViewController {
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
    
    if (self.classification) {
        [self.classificationName setText:self.classification.name];
        
        [self.titleItem setTitle:NSLocalizedStringFromTable(@"EditClassification", @"Classifications", @"Edit Classification")];
    }
    else {
        [self.classificationName setText:@""];
        
        [self.titleItem setTitle:NSLocalizedStringFromTable(@"AddClassification", @"Classifications", @"Add Classification")];
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
    [[ISADataManager Instance] registerClassificationChangedDelegate:self];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[ISADataManager Instance] unregisterStoreChangedDelegate:self];
    [[ISADataManager Instance] unregisterClassificationChangedDelegate:self];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    if ([self.classificationName.text length] > 0) {
        ICLCoreDataManager* dataManager = [ICLCoreDataManager Instance];
        
        Classification* classification = self.classification;
        
        if (!classification) {
            classification = [NSEntityDescription insertNewObjectForEntityForName:@"Classification"
                                                           inManagedObjectContext:[dataManager managedObjectContext]];
        }
        
        classification.name = self.classificationName.text;
        
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
    self.classification = nil;
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

#pragma ClassificationChangedDelegate support

- (void) classificationAdded:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // Nothing to do in response to an add.
}

- (void) classificationDeleted:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // We only care if the classification we are editing was deleted.
    if (self.classification && (self.classification == classification)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* messageTitle = NSLocalizedStringFromTable(@"Deleted.Title", @"Classifications", @"Current Classification Deleted");
            NSString* message = NSLocalizedStringFromTable(@"Deleted.Message", @"Classifications", @"The Classification you are editing was deleted remotely. You will be returned to the main screen.");
            
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

- (void) classificationUpdated:(Classification *)classification remoteChange:(BOOL)isRemoteChange {
    // We only care if the classification we are editing was updated.
    if (isRemoteChange && self.classification && (self.classification == classification)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* messageTitle = NSLocalizedStringFromTable(@"Modified.Title", @"Classifications", @"Current Classification Modified");
            NSString* message = NSLocalizedStringFromTable(@"Modified.Message", @"Classifications", @"The Classification you are editing was modified remotely. You will be returned to the main screen.");
            
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
