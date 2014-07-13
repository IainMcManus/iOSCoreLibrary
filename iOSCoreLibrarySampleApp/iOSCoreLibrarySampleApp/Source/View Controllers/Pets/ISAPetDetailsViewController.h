//
//  ISAPetDetailsViewController.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Pet;

@interface ISAPetDetailsViewController : UIViewController

@property (strong, nonatomic) Pet* pet;

@property (weak, nonatomic) IBOutlet UINavigationItem *titleItem;
@property (weak, nonatomic) IBOutlet UITextField *petName;
@property (weak, nonatomic) IBOutlet UITableView *ownersTable;
@property (weak, nonatomic) IBOutlet UITableView *classificationsTable;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
