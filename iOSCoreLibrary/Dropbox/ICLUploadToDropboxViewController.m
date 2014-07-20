//
//  ICLUploadToDropboxViewController.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 7/05/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLUploadToDropboxViewController.h"

#if ICL_Using_Dropbox

#import "UIButton+applyGlassStyle.h"
#import "UIViewController+Extensions.h"

#import <DropboxSDK/DropboxSDK.h>

@interface ICLUploadToDropboxViewController () <DBRestClientDelegate, UIPopoverControllerDelegate, UIAlertViewDelegate>

@end

@implementation ICLUploadToDropboxViewController {
    UINavigationController* _navigationViewController;
    UIPopoverController* _popoverViewController;
    
    NSTimer* _displayUpdateTimer;
    NSInteger _newProgress;
    NSInteger _lastProgress;
    
    EAGLContext* _eaglContext;
    CIContext* _coreImageContext;
    
    CIFilter* _gaussianBlurFilter;
    CIFilter* _blendFilter;
    
    BOOL _downloadFinished;
    BOOL _downloadFailed;
}

+ (id) create:(NSString*) title sourceFile:(NSString*) sourceFile destinationPath:(NSString*) destinationPath appearanceOptions:(NSDictionary*) appearanceOptions errorTitle:(NSString*) errorTitle errorMessage:(NSString*) errorMessage retryText:(NSString*) retryText cancelText:(NSString*) cancelText {
    NSBundle* libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"iOSCoreLibraryBundle" withExtension:@"bundle"]];
    
    ICLUploadToDropboxViewController* viewController = nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        viewController = [[ICLUploadToDropboxViewController alloc] initWithNibName:@"ICLUploadToDropboxViewController" bundle:libBundle];
    }
    else {
        viewController = [[ICLUploadToDropboxViewController alloc] initWithNibName:@"ICLUploadToDropboxViewController~iPhone" bundle:libBundle];
    }
    
    NSMutableDictionary* updatedAppearanceOptions = appearanceOptions ? [appearanceOptions mutableCopy] : [[NSMutableDictionary alloc] init];
    
    updatedAppearanceOptions[@"errorTitle"] = errorTitle;
    updatedAppearanceOptions[@"errorMessage"] = errorMessage;
    updatedAppearanceOptions[@"retryText"] = retryText;
    updatedAppearanceOptions[@"cancelText"] = cancelText;
    
    viewController.title = title;
    viewController.appearanceOptions = updatedAppearanceOptions;
    viewController.sourceFile = sourceFile;
    viewController.destinationPath = destinationPath;
    viewController.filename = [[sourceFile pathComponents] lastObject];
    
    return viewController;
}

- (void) show {
    // Setup a navigation controller for the picker view
    _navigationViewController = [[UINavigationController alloc] initWithRootViewController:self];
    [_navigationViewController setNavigationBarHidden:YES];
    
    UIViewController* activeVC = [self topViewController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Create the popover
        _popoverViewController = [[UIPopoverController alloc] initWithContentViewController:_navigationViewController];
        [_popoverViewController setDelegate:self];
        
        CGRect viewBounds = activeVC.view.bounds;
        CGRect centeredRect = CGRectMake(viewBounds.size.width/2, viewBounds.size.height/2, 1, 1);
        
        [_popoverViewController presentPopoverFromRect:centeredRect inView:activeVC.view permittedArrowDirections:0 animated:YES];
        
        [self.view setBackgroundColor:[UIColor clearColor]];
    }
    else {
        [activeVC presentViewController:_navigationViewController animated:YES completion:nil];
    }
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
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat viewWidth = 320.0f;
        CGFloat viewHeight = 400.0f;
        
        CGSize contentSize = CGSizeMake(viewWidth, viewHeight);
        
        // set content size for versions < iOS 7
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7) {
            self.contentSizeForViewInPopover = contentSize;
        } // iOS7 and above
        else {
            self.preferredContentSize = contentSize;
        }
    }
    
    [self.titleItem setTitle:self.title];
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    
    // create the destination path
    [self.restClient createFolder:self.destinationPath];
    
    // check if the file is already present
    [self.restClient loadMetadata:[self.destinationPath stringByAppendingPathComponent:self.filename]];
    
    if (self.appearanceOptions[@"BackgroundImage"]) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.appearanceOptions[@"BackgroundImage"]]];
        
        imgView.frame = self.view.bounds;
        imgView.contentMode = UIViewContentModeTopLeft;
        
        [self.view addSubview:imgView];
        [self.view sendSubviewToBack:imgView];
        [self.view setBackgroundColor:[UIColor clearColor]];
    }
    
    _downloadFailed = NO;
    _downloadFinished = NO;
    
    _eaglContext = nil;
    _coreImageContext = nil;
    _gaussianBlurFilter = nil;
    _blendFilter = nil;
    
    [self.doneButton applyGlassStyle:egbsSmall colour:self.doneButton.backgroundColor];
    [self.doneButton setHidden:YES];
    
    _newProgress = 0;
    _lastProgress = -1;
    [self updateProgressImage];
}

- (void) displayUpdateTimer:(NSTimer*) inTimer {
    //    if (_newProgress < 100) {
    //        _newProgress = MIN(100, MAX(_newProgress + 5, 0));
    //    }
    //    else {
    //        _newProgress = 0;
    //        _downloadFailed = !_downloadFailed;
    //    }
    
    [self updateProgressImage];
}

- (void) updateProgressImage {
    if (_newProgress != _lastProgress) {
        [self.progressView setImage:[self generateProgressImage:_newProgress imageSize:self.progressView.frame.size]];
        _lastProgress = _newProgress;
    }
}

- (UIImage*) generateProgressArc:(NSInteger) progressPercentage imageSize:(CGSize) imageSize meterWidth:(CGFloat) meterWidth radiusOffset:(CGFloat) radiusOffset {
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat maximumRadius = MIN(width / 2.0f, height / 2.0f);
    CGFloat radius = maximumRadius - (meterWidth/2.0f) - radiusOffset;
    CGPoint origin = CGPointMake(width / 2.0f, height / 2.0f);
    
    UIImage* image = nil;
    
    UIColor* colour = nil;
    
    if (!_downloadFailed) {
        if (_downloadFinished) {
            colour = self.appearanceOptions[@"MeterColourForSuccess"];
        }
        else {
            colour = self.appearanceOptions[@"MeterColour"];
        }
    }
    else {
        colour = self.appearanceOptions[@"MeterColourForFailure"];
    }
    
    if (!colour) {
        colour = [UIColor whiteColor];
    }
    CGColorRef cgColour = colour.CGColor;
    
    @autoreleasepool {
        // setup the context so we can modify the image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        UIBezierPath* arc = [UIBezierPath bezierPathWithArcCenter:origin
                                                           radius:radius
                                                       startAngle:-M_PI_2
                                                         endAngle:-M_PI_2+(M_PI*2.0f*progressPercentage/100.0f)
                                                        clockwise:YES];
        
        CGPathRef shape = CGPathCreateCopyByStrokingPath(arc.CGPath, NULL, meterWidth, kCGLineCapButt, kCGLineJoinMiter, 10.0f);
        
        CGContextBeginPath(context);
        CGContextAddPath(context, shape);
        CGContextSetFillColorWithColor(context, cgColour);
        CGContextFillPath(context);
        CGPathRelease(shape);
        
        UIFont* textFont = [UIFont systemFontOfSize:40.0f];
        NSString* workingText = [NSString stringWithFormat:@"%3ld%%", (long)progressPercentage];
        CGSize textSize = [workingText sizeWithFont:textFont];
        CGFloat xOffset = (width - textSize.width) / 2;
        CGFloat yOffset = (height - textSize.height) / 2;
        
        CGRect textRect = CGRectMake(xOffset, yOffset, textSize.width, textSize.height);
        
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, cgColour);
        
        [workingText drawInRect:textRect withFont:textFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentLeft];
        
        CGContextRestoreGState(context);
        
        UIGraphicsPopContext();
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (UIImage*) generateProgressImage:(CGFloat) progressPercentage imageSize:(CGSize) imageSize {
    // setup the contexts if they are missing
    if (!_eaglContext || !_coreImageContext) {
        _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _coreImageContext = [CIContext contextWithEAGLContext:_eaglContext
                                                      options:@{ kCIContextWorkingColorSpace : [NSNull null] }];
    }
    
    // setup the filters if they don't exist yet
    if (!_gaussianBlurFilter || !_blendFilter) {
        _gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        
        [_gaussianBlurFilter setDefaults];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
            [_gaussianBlurFilter setValue:@(10) forKey:kCIInputRadiusKey];
        }
        else {
            [_gaussianBlurFilter setValue:@(10) forKey:@"inputRadius"];
        }
        
        _blendFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [_blendFilter setDefaults];
    }
    
    UIImage* outputImage = nil;
    
    @autoreleasepool {
        UIImage* largeMeter = [self generateProgressArc:progressPercentage imageSize:imageSize meterWidth:50.0f radiusOffset:0.0f];
        UIImage* smallMeter = [self generateProgressArc:progressPercentage imageSize:imageSize meterWidth:30.0f radiusOffset:10.0f];
        
        [_gaussianBlurFilter setValue:[CIImage imageWithCGImage:largeMeter.CGImage] forKey:kCIInputImageKey];
        
        [_blendFilter setValue:[_gaussianBlurFilter valueForKey:kCIOutputImageKey] forKey:kCIInputBackgroundImageKey];
        [_blendFilter setValue:[CIImage imageWithCGImage:smallMeter.CGImage] forKey:kCIInputImageKey];
        
        CIImage* blendedImage = [_blendFilter valueForKey:kCIOutputImageKey];
        
        CGRect extent = [blendedImage extent];
        CGImageRef blendedCGImage = [_coreImageContext createCGImage:blendedImage fromRect:extent];
        
        outputImage = [UIImage imageWithCGImage:blendedCGImage];
        CGImageRelease(blendedCGImage);
    }
    
    return outputImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _displayUpdateTimer = [NSTimer timerWithTimeInterval:0.5f target:self selector:@selector(displayUpdateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_displayUpdateTimer forMode:NSRunLoopCommonModes];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    // file already exists so overwrite it
    [self.restClient uploadFile:self.filename toPath:self.destinationPath withParentRev:metadata.rev fromPath:self.sourceFile];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    // 404 error is the only valid one that allows us to continue. it will happen if the file is not already present
    if ([error code] == 404) {
        // failed to load the metadata. assume the file is new
        [self.restClient uploadFile:self.filename toPath:self.destinationPath withParentRev:nil fromPath:self.sourceFile];
    }
    else {
        [self handleFailure:error];
    }
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    dispatch_async(dispatch_get_main_queue(), ^{
        _newProgress = 100;
        _lastProgress = 99;
        _downloadFailed = NO;
        _downloadFinished = YES;
        [self updateProgressImage];
    });
    
    [self.doneButton setHidden:NO];
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    [self handleFailure:error];
}

- (void) handleFailure:(NSError *)error {
    _downloadFailed = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateProgressImage];
        
        [[[UIAlertView alloc] initWithTitle:self.appearanceOptions[@"errorTitle"]
                                    message:[NSString stringWithFormat:self.appearanceOptions[@"errorMessage"], [error localizedDescription]]
                                   delegate:self
                          cancelButtonTitle:self.appearanceOptions[@"retryText"]
                          otherButtonTitles:self.appearanceOptions[@"cancelText"], nil] show];
    });
}

- (void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    _newProgress = MIN(100, MAX(progress * 100, 0));
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        _newProgress = 0;
        _lastProgress = -1;
        _downloadFailed = NO;
        [self.restClient loadMetadata:[self.destinationPath stringByAppendingPathComponent:self.filename]];
    }
    else if (buttonIndex == 1) {
        [self doneButtonSelected:nil];
    }
}

- (IBAction)doneButtonSelected:(id)sender {
    [_displayUpdateTimer invalidate];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_popoverViewController dismissPopoverAnimated:YES];
        
        _navigationViewController = nil;
        _popoverViewController = nil;
        
        if (self.delegate) {
            [self.delegate uploadToDropboxViewDidFinish:self uploaded:!_downloadFailed];
        }
    }
    else {
        [_navigationViewController dismissViewControllerAnimated:YES completion:^{
            if (self.delegate) {
                [self.delegate uploadToDropboxViewDidFinish:self uploaded:!_downloadFailed];
            }
        }];
    }
}

- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return NO;
}

- (void) cancelUpload {
    [_restClient cancelAllRequests];
    
    _downloadFailed = YES;
    [self.doneButton setHidden:NO];
}

@end

#endif // ICL_Using_Dropbox