//
//  ISASettingsTabViewController.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 12/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISASettingsTabViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *toggleiCloudButton;
@property (weak, nonatomic) IBOutlet UILabel *iCloudNotAvailableMessage;

- (IBAction)toggleiCloud:(id)sender;

@end
