//
//  ISAPetsTabViewController.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 12/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISAPetsTabViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *petsTable;

@property (weak, nonatomic) IBOutlet UINavigationBar *mainNavigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPetButton;

@end
