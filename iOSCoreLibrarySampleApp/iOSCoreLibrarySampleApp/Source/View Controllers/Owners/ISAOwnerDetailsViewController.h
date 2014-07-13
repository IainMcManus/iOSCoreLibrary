//
//  ISAOwnerDetailsViewController.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Owner;

@interface ISAOwnerDetailsViewController : UIViewController

@property (strong, nonatomic) Owner* owner;

@property (weak, nonatomic) IBOutlet UINavigationItem *titleItem;
@property (weak, nonatomic) IBOutlet UITextField *ownerName;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
