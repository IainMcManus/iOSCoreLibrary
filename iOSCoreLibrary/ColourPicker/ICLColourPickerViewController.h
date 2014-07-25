//
//  ICLColourPickerViewController.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 22/06/13.
//  Copyright (c) 2013 Iain McManus. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ICLColourPickerViewControllerDelegate;

@interface ICLColourPickerViewController : UIViewController

@property (weak, nonatomic) id <ICLColourPickerViewControllerDelegate> delegate;

@property (strong, nonatomic) UIColor* CurrentColour;
@property (strong, nonatomic) NSString* TitleText;
@property (assign, nonatomic) NSInteger Tag;
@property (strong, nonatomic) NSString* BackgroundImage;
@property (assign, nonatomic) float BackgroundImageAlpha;

@property (weak, nonatomic) IBOutlet UINavigationBar *TitleBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *TitleItem;

@property (weak, nonatomic) IBOutlet UIView *rgbPanel;
@property (weak, nonatomic) IBOutlet UIImageView *colourWheelView;
@property (weak, nonatomic) IBOutlet UIImageView *brightnessSelector;
@property (weak, nonatomic) IBOutlet UIImageView *redSelector;
@property (weak, nonatomic) IBOutlet UIImageView *greenSelector;
@property (weak, nonatomic) IBOutlet UIImageView *blueSelector;
@property (weak, nonatomic) IBOutlet UITextField *redField;
@property (weak, nonatomic) IBOutlet UITextField *greenField;
@property (weak, nonatomic) IBOutlet UITextField *blueField;

+ (id) create;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)redFieldChanged:(id)sender;
- (IBAction)greenFieldChanged:(id)sender;
- (IBAction)blueFieldChanged:(id)sender;

@end

@protocol ICLColourPickerViewControllerDelegate <NSObject>

@required
- (void) colourPickerViewController:(ICLColourPickerViewController*) viewController didSelectColour:(UIColor*) colour;
- (void) colourPickerViewControllerDidCancel:(ICLColourPickerViewController*) viewController;

@end;
