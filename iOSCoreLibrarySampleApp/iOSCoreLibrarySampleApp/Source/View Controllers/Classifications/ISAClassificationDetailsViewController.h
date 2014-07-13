//
//  ISAClassificationDetailsViewController.h
//  iOSCoreLibrarySampleApp
//
//  Created by Iain McManus on 13/07/2014.
//  Copyright (c) 2014 Injaia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Classification;

@interface ISAClassificationDetailsViewController : UIViewController

@property (strong, nonatomic) Classification* classification;

@property (weak, nonatomic) IBOutlet UINavigationItem *titleItem;
@property (weak, nonatomic) IBOutlet UITextField *classificationName;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
