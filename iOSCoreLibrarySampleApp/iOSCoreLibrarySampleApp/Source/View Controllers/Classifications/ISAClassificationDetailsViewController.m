//
//  ISAClassificationDetailsViewController.m
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import "ISAClassificationDetailsViewController.h"

#import "Classification+Extensions.h"

@interface ISAClassificationDetailsViewController () <StoreChangedDelegate>

@end

@implementation ISAClassificationDetailsViewController

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
    }
    else {
        [self.classificationName setText:@""];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark StoreChangedDelegate Support

- (void) storeWillChange {
}

- (void) storeDidChange {
}
@end
