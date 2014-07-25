//
//  ICLAlertViewController.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 4/05/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLAlertViewController.h"
#import "UIButton+applyGlassStyle.h"
#import "UIViewController+Extensions.h"
#import "UIColor+extensions.h"

@interface ICLAlertViewController () <UIPopoverControllerDelegate>

@end

@implementation ICLAlertViewController {
    UINavigationController* _alertViewNavController;
    UIPopoverController* _alertViewPopoverController;
}

+ (id) create:(NSString*) title optionNames:(NSArray*) optionNames optionDescriptions:(NSArray*) optionDescriptions appearanceOptions:(NSDictionary*) appearanceOptions {
    NSBundle* libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"iOSCoreLibraryBundle" withExtension:@"bundle"]];
    
    ICLAlertViewController* viewController = nil;
    
    // fail if the option counts don't match
    if ([optionNames count] != [optionDescriptions count]) {
        NSLog(@"ERROR: The number of option names (%lu) did not match the number of descriptions (%lu)", (unsigned long)[optionNames count], (unsigned long)[optionDescriptions count]);
        
        assert(0);
        return nil;
    }
    
    // handle too few options
    if ([optionNames count] < 2) {
        NSLog(@"ERROR: Too few options were provided (%lu). 2 or 3 options are required.", (unsigned long)[optionNames count]);
        
        assert(0);
        return nil;
    }
    
    // handle too many options
    if ([optionNames count] > 3) {
        NSLog(@"ERROR: Too many options were provided (%lu). 2 or 3 options are required.", (unsigned long)[optionNames count]);
        
        assert(0);
        return nil;
    }

    // load the correct XIB for the number of options
    NSString* baseXIBName = [optionNames count] == 2 ? @"ICLAlertViewController2" : @"ICLAlertViewController3";
    if (Using_iPad) {
        viewController = [[ICLAlertViewController alloc] initWithNibName:baseXIBName bundle:libBundle];
    }
    else {
        viewController = [[ICLAlertViewController alloc] initWithNibName:[baseXIBName stringByAppendingString:@"~iPhone"] bundle:libBundle];
    }
    
    viewController.title = title;
    viewController.appearanceOptions = appearanceOptions;
    viewController.optionNames = optionNames;
    viewController.optionDescriptions = optionDescriptions;
    
    return viewController;
}

- (void) show {
    // Setup a navigation controller for the picker view
    _alertViewNavController = [[UINavigationController alloc] initWithRootViewController:self];
    [_alertViewNavController setNavigationBarHidden:YES];
    
    UIViewController* activeVC = [self topViewController];
    
    if (Using_iPad) {
        // Create the popover
        _alertViewPopoverController = [[UIPopoverController alloc] initWithContentViewController:_alertViewNavController];
        [_alertViewPopoverController setDelegate:self];

        CGRect viewBounds = activeVC.view.bounds;
        CGRect centeredRect = CGRectMake(viewBounds.size.width/2, viewBounds.size.height/2, 1, 1);
        
        [_alertViewPopoverController presentPopoverFromRect:centeredRect inView:activeVC.view permittedArrowDirections:0 animated:YES];
        
        [self.optionContainerView setBackgroundColor:[UIColor clearColor]];
        [self.view setBackgroundColor:[UIColor clearColor]];
    }
    else {
        [activeVC presentViewController:_alertViewNavController animated:YES completion:nil];
    }
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return NO;
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
    
    if (Using_iPad) {
        CGFloat viewWidth = 600.0f;
        CGFloat viewHeight = 400.0f;
        
        CGSize contentSize = CGSizeMake(viewWidth, viewHeight);
        
        if (Using_iOS7OrAbove) {
            self.preferredContentSize = contentSize;
        }
        else {
            self.contentSizeForViewInPopover = contentSize;
        }
    }
    
    [self.titleItem setTitle:self.title];
    
    // Set the button names
    [self.option1Button setTitle:self.optionNames[0] forState:UIControlStateNormal];
    [self.option2Button setTitle:self.optionNames[1] forState:UIControlStateNormal];
    if ([self.optionNames count] == 3) {
        [self.option3Button setTitle:self.optionNames[2] forState:UIControlStateNormal];
    }

    // Set the descriptions
    [self.option1Description setText:self.optionDescriptions[0]];
    [self.option2Description setText:self.optionDescriptions[1]];
    if ([self.optionNames count] == 3) {
        [self.option3Description setText:self.optionDescriptions[2]];
    }

    // for the iPad version set the titles
    if (Using_iPad) {
        [self.option1Title setText:self.optionNames[0]];
        [self.option2Title setText:self.optionNames[1]];
        
        if ([self.optionNames count] == 3) {
            [self.option3Title setText:self.optionNames[2]];
        }
    }
    
    // Determine the panel colours
    UIColor* panelColour = self.appearanceOptions[@"PanelColour"];
    if (!panelColour) {
        panelColour = [UIColor colorWithHue:220.0f/360.0f saturation:0.25f brightness:0.25f alpha:0.5f];
    }
    
    UIColor* panel1Colour = self.appearanceOptions[@"Panel1Colour"];
    if (!panel1Colour) {
        panel1Colour = panelColour;
    }
    UIColor* panel2Colour = self.appearanceOptions[@"Panel2Colour"];
    if (!panel2Colour) {
        panel2Colour = panelColour;
    }
    UIColor* panel3Colour = self.appearanceOptions[@"Panel3Colour"];
    if (!panel3Colour) {
        panel3Colour = panelColour;
    }
    
    // Set all of the panel colours
    [self.option1View setBackgroundColor:panel1Colour];
    [self.option2View setBackgroundColor:panel2Colour];
    if ([self.optionNames count] == 3) {
        [self.option3View setBackgroundColor:panel2Colour];
    }
    
    // Determine the colour for each button
    UIColor* buttonColour = self.appearanceOptions[@"ButtonColour"];
    if (!buttonColour) {
        buttonColour = [UIColor colorWithHue:220.0f/360.0f saturation:0.5f brightness:0.5f alpha:1.0f];
    }
    
    UIColor* button1Colour = self.appearanceOptions[@"Button1Colour"];
    if (!button1Colour) {
        button1Colour = buttonColour;
    }
    UIColor* button2Colour = self.appearanceOptions[@"Button2Colour"];
    if (!button2Colour) {
        button2Colour = buttonColour;
    }
    UIColor* button3Colour = self.appearanceOptions[@"Button3Colour"];
    if (!button3Colour) {
        button3Colour = buttonColour;
    }
    
    // Set all of the button colours
    [self.option1Button setBackgroundColor:button1Colour];
    [self.option2Button setBackgroundColor:button2Colour];
    if ([self.optionNames count] == 3) {
        [self.option3Button setBackgroundColor:button3Colour];
    }
    
    // auto set the description and title colours
    if ([panel1Colour perceivedBrightness] < 0.5f) {
        [self.option1Description setTextColor:[UIColor whiteColor]];
        
        if (Using_iPad) {
            [self.option1Title setTextColor:[UIColor whiteColor]];
        }
    }
    if ([panel2Colour perceivedBrightness] < 0.5f) {
        [self.option2Description setTextColor:[UIColor whiteColor]];
        
        if (Using_iPad) {
            [self.option2Title setTextColor:[UIColor whiteColor]];
        }
    }
    if ([self.optionNames count] == 3) {
        if ([panel3Colour perceivedBrightness] < 0.5f) {
            [self.option3Description setTextColor:[UIColor whiteColor]];
            
            if (Using_iPad) {
                [self.option3Title setTextColor:[UIColor whiteColor]];
            }
        }
    }
    
    // autoset the button text colour
    if ([button1Colour perceivedBrightness] < 0.5f) {
        [self.option1Button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    if ([button2Colour perceivedBrightness] < 0.5f) {
        [self.option2Button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    if ([self.optionNames count] == 3) {
        if ([button3Colour perceivedBrightness] < 0.5f) {
            [self.option3Button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }
    
    if (self.appearanceOptions[@"BackgroundImage"]) {
        UIImage* image = [UIImage imageNamed:self.appearanceOptions[@"BackgroundImage"]];
        
        if (image) {
            UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
            
            imgView.frame = self.view.bounds;
            imgView.contentMode = UIViewContentModeTopLeft;
            
            [self.view addSubview:imgView];
            [self.view sendSubviewToBack:imgView];
            [self.view setBackgroundColor:[UIColor clearColor]];
        }
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Apply the glass style to the buttons
    [self.option1Button applyGlassStyle:egbsSmall colour:self.option1Button.backgroundColor autoColourText:YES];
    [self.option2Button applyGlassStyle:egbsSmall colour:self.option2Button.backgroundColor autoColourText:YES];
    if ([self.optionNames count] == 3) {
        [self.option3Button applyGlassStyle:egbsSmall colour:self.option3Button.backgroundColor autoColourText:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)selectedOption1:(id)sender {
    [self dismissAlertView:1];
}

- (IBAction)selectedOption2:(id)sender {
    [self dismissAlertView:2];
}

- (IBAction)selectedOption3:(id)sender {
    [self dismissAlertView:3];
}

- (void) dismissAlertView:(NSUInteger) selectedOption {
    if (Using_iPad) {
        [_alertViewPopoverController dismissPopoverAnimated:YES];
        
        _alertViewNavController = nil;
        _alertViewPopoverController = nil;
        
        [self.delegate alertViewControllerDidFinish:self selectedOption:selectedOption];
    }
    else {
        [_alertViewNavController dismissViewControllerAnimated:YES completion:^{
            [self.delegate alertViewControllerDidFinish:self selectedOption:selectedOption];
        }];
    }
}
@end
