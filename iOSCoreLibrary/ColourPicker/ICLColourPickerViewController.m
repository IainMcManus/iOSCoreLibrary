//
//  ICLColourPickerViewController.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 22/06/13.
//  Copyright (c) 2013 Iain McManus. All rights reserved.
//

#import "ICLColourPickerViewController.h"
#import "UITextField+matchesRegex.h"

NSString* ICL_Regex_RGB = @"^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$";

#if TARGET_OS_IPHONE

@interface ICLColourPickerViewController ()

@end

@implementation ICLColourPickerViewController {
    float _colourWheelImageScale;
    float _colourWheelImageScaleX;
    float _colourWheelImageScaleY;
    float _colourWheelRadius;
    UIImage* _colourWheelImage;
    UIImage* _valueImage;
    UIImage* _redSliderImage;
    UIImage* _greenSliderImage;
    UIImage* _blueSliderImage;
    
    UIColor* _workingColour;
}

+ (id) create {
    NSBundle* libBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"iOSCoreLibraryBundle" withExtension:@"bundle"]];
    
    ICLColourPickerViewController* viewController = nil;
    
    // Instantiate the correct view controller for the platform
    if (Using_iPad) {
        viewController = [[ICLColourPickerViewController alloc] initWithNibName:@"ICLColourPickerViewController" bundle:libBundle];
    }
    else {
        viewController = [[ICLColourPickerViewController alloc] initWithNibName:@"ICLColourPickerViewController~iPhone" bundle:libBundle];
    }
    
    viewController.BackgroundImageAlpha = 1.0f;
    
    return viewController;
}


typedef struct
{
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} PixelRGBA;

// Converts from HSV to RGB (expanded to RGBA)
- (void)fillPixelRGBAFromHSV:(float) hue saturation:(float) saturation value:(float) value pixelRGBA:(PixelRGBA*) pixelRGBA {
    float huePrime = hue * 6.0f;
    int sector = floorf(huePrime);
    
    float hueResidual = huePrime - sector;
    float p = value * (1.0f - saturation);
    float q = value * (1.0f - saturation * hueResidual);
    float t = value * (1.0f - saturation * (1.0f - hueResidual));
    
    pixelRGBA->a = 255;
    
    switch(sector) {
        case 0:
        case 6:
            pixelRGBA->r = 255 * value;
            pixelRGBA->g = 255 * t;
            pixelRGBA->b = 255 * p;
            break;
        case 1:
            pixelRGBA->r = 255 * q;
            pixelRGBA->g = 255 * value;
            pixelRGBA->b = 255 * p;
            break;
        case 2:
            pixelRGBA->r = 255 * p;
            pixelRGBA->g = 255 * value;
            pixelRGBA->b = 255 * t;
            break;
        case 3:
            pixelRGBA->r = 255 * p;
            pixelRGBA->g = 255 * q;
            pixelRGBA->b = 255 * value;
            break;
        case 4:
            pixelRGBA->r = 255 * t;
            pixelRGBA->g = 255 * p;
            pixelRGBA->b = 255 * value;
            break;
        default:
            pixelRGBA->r = 255 * value;
            pixelRGBA->g = 255 * p;
            pixelRGBA->b = 255 * q;
            break;
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

    // Set safe defaults
    _colourWheelRadius = 1.0f;
    _colourWheelImageScale = 1.0f;
    _colourWheelImageScaleX = 1.0f;
    _colourWheelImageScaleY = 1.0f;
    _colourWheelImage = nil;
    _valueImage = nil;
    _redSliderImage = nil;
    _greenSliderImage = nil;
    _blueSliderImage = nil;
    
    // If we're on iPad then we need to control the size of the colour picker
    if (Using_iPad) {
        if (Using_iOS7OrAbove) {
            self.preferredContentSize = CGSizeMake(400, self.view.frame.size.height);
        }
        else {
            self.contentSizeForViewInPopover = CGSizeMake(400, self.view.frame.size.height);
        }
    }
    
    self.TitleItem.title = self.TitleText;
    
    _workingColour = [self.CurrentColour copy];
    
    _colourWheelImage = [self createColourWheelBitmap:self.colourWheelView.frame];
    [self.colourWheelView setImage:_colourWheelImage];
    
    PixelRGBA white = {255, 255, 255, 255};
    PixelRGBA black = {0, 0, 0, 255};
    
    // Create and assign the gradient image
    _valueImage = [self createGradientBitmap:self.brightnessSelector.frame startColour:black endColour:white borderSize:5];
    [self.brightnessSelector setImage:[_valueImage copy]];
    
    // Create and assign the red component image
    PixelRGBA red = {255, 0, 0, 255};
    _redSliderImage = [self createGradientBitmap:self.brightnessSelector.frame startColour:black endColour:red borderSize:5];
    [self.redSelector setImage:[_redSliderImage copy]];
    
    // Create and assign the green component image
    PixelRGBA green = {0, 255, 0, 255};
    _greenSliderImage = [self createGradientBitmap:self.brightnessSelector.frame startColour:black endColour:green borderSize:5];
    [self.greenSelector setImage:[_greenSliderImage copy]];
    
    // Create and assign the blue component image
    PixelRGBA blue = {0, 0, 255, 255};
    _blueSliderImage = [self createGradientBitmap:self.brightnessSelector.frame startColour:black endColour:blue borderSize:5];
    [self.blueSelector setImage:[_blueSliderImage copy]];
    
    // Taps will jump to a specific colour (based on where the user tapped)
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(panAndTapGesture:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    // Pans are used to detect the user moving a slider
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAndTapGesture:)];
    panGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    // Register observers for the red, green and blue text fields changing for validation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(redFieldChanged:) name:UITextFieldTextDidChangeNotification object:self.redField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greenFieldChanged:) name:UITextFieldTextDidChangeNotification object:self.greenField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blueFieldChanged:) name:UITextFieldTextDidChangeNotification object:self.blueField];
    
    // default to solid white background
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Add the background image if one was provided
    if (self.BackgroundImage && ([self.BackgroundImage length] > 0)) {
        UIImage* image = [UIImage imageNamed:self.BackgroundImage];
        
        if (image) {
            UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
            
            imgView.frame = self.view.bounds;
            imgView.contentMode = UIViewContentModeScaleAspectFill;
            imgView.alpha = self.BackgroundImageAlpha;
            
            [self.view addSubview:imgView];
            [self.view sendSubviewToBack:imgView];
            
            [imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.view addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"H:|-0-[imgView]-0-|"
                                       options:NSLayoutFormatDirectionLeadingToTrailing
                                       metrics:nil
                                       views:NSDictionaryOfVariableBindings(imgView)]];
            [self.view addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"V:|-0-[imgView]-0-|"
                                       options:NSLayoutFormatDirectionLeadingToTrailing
                                       metrics:nil
                                       views:NSDictionaryOfVariableBindings(imgView)]];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateColourWheelRadius];
    [self updateForCurrentColour];
}

- (void)updateColourWheelRadius {
    _colourWheelImageScaleX = self.colourWheelView.image.size.width / self.colourWheelView.frame.size.width;
    _colourWheelImageScaleY = self.colourWheelView.image.size.height / self.colourWheelView.frame.size.height;
    
    _colourWheelImageScale = MAX(_colourWheelImageScaleX, _colourWheelImageScaleY);
    _colourWheelRadius = MIN(self.colourWheelView.image.size.width, self.colourWheelView.image.size.height) / (_colourWheelImageScale * 2.0f);
}

// Creates a UIImage with a horizontal gradient from inStartColour to inEndColour
- (UIImage*)createGradientBitmap:(CGRect) inRect startColour:(PixelRGBA) inStartColour endColour:(PixelRGBA) inEndColour borderSize:(int) inBorderSize
{
    int width = inRect.size.width;
    int height = inRect.size.height;
    int bytesPerRow = width * 4;
    
    // Allocate the raw pixel buffer
    PixelRGBA* imageData = malloc(width * height * sizeof(PixelRGBA));
    memset(imageData, 0, width * height * sizeof(PixelRGBA));
    
    // Generate the pixel data using a simple lerp between the R, G, B and A components
    for (int x = 0; x < width; ++x) {
        float percentage = (float)x / width;
        
        for (int y = inBorderSize; y < (height - inBorderSize); ++y) {
            PixelRGBA* currentPixel = &imageData[x + (y * width)];
            
            currentPixel->r = inStartColour.r + (inEndColour.r - inStartColour.r) * percentage;
            currentPixel->g = inStartColour.g + (inEndColour.g - inStartColour.g) * percentage;
            currentPixel->b = inStartColour.b + (inEndColour.b - inStartColour.b) * percentage;
            currentPixel->a = inStartColour.a + (inEndColour.a - inStartColour.a) * percentage;
        }
    }
    
    // Create a bitmap context using the source data
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, bytesPerRow, colourSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);
    
    // Retrieve a UIImage from the context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage* image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    CGContextRelease(context);
    
    free(imageData);
    
    return image;
}

// Creates a square UIImage centred in inRect that contains the colour wheel
- (UIImage*)createColourWheelBitmap:(CGRect) inRect
{
    int width = inRect.size.width;
    int height = inRect.size.height;
    int bytesPerRow = width * 4;
    
    // Allocate the raw pixel buffer that we will draw into
    PixelRGBA* imageData = malloc(width * height * sizeof(PixelRGBA));
    memset(imageData, 0, width * height * sizeof(PixelRGBA));
    
    int maxRadius = MIN(width / 2, height / 2) - 2;
    int centreX = width / 2;
    int centreY = height / 2;
    
    // We traverse each pixel in the bitmap
    for (int y = 0; y < height; ++y) {
        int pixelY = y - centreY;

        for (int x = 0; x < width; ++x) {
            PixelRGBA* currentPixel = &imageData[x + (y * width)];
            
            int pixelX = x - centreX;
            int pixelRadius = sqrtf((pixelX * pixelX) + (pixelY * pixelY));
            
            // If the pixel's radius is within the colour wheel then we will draw that pixel
            if (pixelRadius <= maxRadius) {
                // Convert the location to hue and saturation.
                // Hue is based on the angle, Saturation is based on the radius.
                float hue = MAX(0.0f, MIN(1.0f, (atan2f(pixelX, pixelY) + M_PI) / (M_PI * 2.0f)));
                float saturation = MAX(0.0f, MIN(1.0f, (float)pixelRadius / maxRadius));
                
                [self fillPixelRGBAFromHSV:hue saturation:saturation value:1.0f pixelRGBA:currentPixel];
            }
        }
    }
    
    // Construct a bitmap context using the raw pixel data
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, bytesPerRow, colourSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);
   
    // Extract a UIImage from the bitmap context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage* image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    CGContextRelease(context);
    
    free(imageData);
    
    return image;
}

// Converts a given hue and saturation to a pixel location in the colour wheel
- (CGPoint)pointFromHueAndSaturation:(float) inHue saturation:(float) inSaturation wheelRect:(CGRect) inWheelRect wheelRadius:(float) inWheelRadius {
    int centreX = inWheelRect.size.width / 2;
    int centreY = inWheelRect.size.height / 2;
    
    int pointY = inWheelRadius * cosf((inHue * 2.0f * M_PI) - M_PI) * inSaturation;
    int pointX = inWheelRadius * sinf((inHue * 2.0f * M_PI) - M_PI) * inSaturation;
    
    return CGPointMake(pointX + centreX, pointY + centreY);
}

// Converts a pixel location to hue and saturation. Returns YES if the location was on the wheel, NO otherwise.
- (BOOL)hueAndSaturationForPoint:(CGPoint) inLocation wheelRect:(CGRect) inWheelRect wheelRadius:(float) inWheelRadius hue:(float*) outHue saturation:(float*) outSaturation {
    int width = inWheelRect.size.width;
    int height = inWheelRect.size.height;
    
    int centreX = width / 2;
    int centreY = height / 2;
    
    int pointX = inLocation.x - centreX;
    int pointY = inLocation.y - centreY;
    
    int pointRadius = sqrtf((pointX * pointX) + (pointY * pointY));
    
    if (pointRadius > inWheelRadius) {
        return NO;
    }
    
    *outSaturation = (float)pointRadius / inWheelRadius;
    *outHue = MAX(0.0f, MIN(1.0f, (atan2f(pointX, pointY) + M_PI) / (M_PI * 2.0f)));
    
    return YES;
}

- (void) panAndTapGesture:(UIGestureRecognizer*) recognizer {
    [self.view endEditing:YES];
    
    // Pan gestures are remapped to a tap gesture for the corresponding parameter (colour wheel, brightness etc)
    if ((recognizer.state == UIGestureRecognizerStateBegan) || (recognizer.state == UIGestureRecognizerStateChanged) || (recognizer.state == UIGestureRecognizerStateEnded)) {
        CGPoint location = [recognizer locationInView:self.rgbPanel];
        
        if (CGRectContainsPoint(self.colourWheelView.frame, location)) {
            [self colourWheelTapped:[recognizer locationInView:self.colourWheelView]];
        }
        else if (CGRectContainsPoint(self.brightnessSelector.frame, location)) {
            [self brightnessTapped:[recognizer locationInView:self.brightnessSelector]];
        }
        else if (CGRectContainsPoint(self.redSelector.frame, location)) {
            [self redTapped:[recognizer locationInView:self.redSelector]];
        }
        else if (CGRectContainsPoint(self.greenSelector.frame, location)) {
            [self greenTapped:[recognizer locationInView:self.greenSelector]];
        }
        else if (CGRectContainsPoint(self.blueSelector.frame, location)) {
            [self blueTapped:[recognizer locationInView:self.blueSelector]];
        }
    }
}

- (void)colourWheelTapped:(CGPoint) inLocation {
    float hue, saturation;
    
    // Attempt to calculate the hue and saturation for the tapped location
    if ([self hueAndSaturationForPoint:inLocation wheelRect:self.colourWheelView.frame wheelRadius:_colourWheelRadius hue:&hue saturation:&saturation]) {
        CGFloat currentHue, currentSaturation, currentBrightness, currentAlpha;
        [_workingColour getHue:&currentHue saturation:&currentSaturation brightness:&currentBrightness alpha:&currentAlpha];
        
        // If the brightness was 0 (ie. the colour was black) then we force the brightness to full so the current colour
        // will be exactly what the user selected.
        if (currentBrightness == 0.0f) {
            currentBrightness = 1.0f;
        }
        
        _workingColour = [UIColor colorWithHue:hue saturation:saturation brightness:currentBrightness alpha:currentAlpha];
        [self updateForCurrentColour];
    }
}

- (void)brightnessTapped:(CGPoint) inLocation {
    float newBrightness = inLocation.x / (self.brightnessSelector.frame.size.width - 1);
    newBrightness = MIN(1.0f, MAX(0.0f, newBrightness));
    
    CGFloat currentHue, currentSaturation, currentBrightness, currentAlpha;
    [_workingColour getHue:&currentHue saturation:&currentSaturation brightness:&currentBrightness alpha:&currentAlpha];
    
    _workingColour = [UIColor colorWithHue:currentHue saturation:currentSaturation brightness:newBrightness alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (void)redTapped:(CGPoint) inLocation {
    float newRed = inLocation.x / (self.redSelector.frame.size.width - 1);
    newRed = MIN(1.0f, MAX(0.0f, newRed));
    
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    _workingColour = [UIColor colorWithRed:newRed green:currentGreen blue:currentBlue alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (void)greenTapped:(CGPoint) inLocation {
    float newGreen = inLocation.x / (self.redSelector.frame.size.width - 1);
    newGreen = MIN(1.0f, MAX(0.0f, newGreen));
    
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    _workingColour = [UIColor colorWithRed:currentRed green:newGreen blue:currentBlue alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (void)blueTapped:(CGPoint) inLocation {
    float newBlue = inLocation.x / (self.redSelector.frame.size.width - 1);
    newBlue = MIN(1.0f, MAX(0.0f, newBlue));
    
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    _workingColour = [UIColor colorWithRed:currentRed green:currentGreen blue:newBlue alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (IBAction)done:(id)sender {
    self.CurrentColour = _workingColour;
    [self.delegate colourPickerViewController:self didSelectColour:self.CurrentColour];
}

- (IBAction)cancel:(id)sender {
    [self.delegate colourPickerViewControllerDidCancel:self];
}

- (void)redFieldChanged:(NSNotification*) inNotification {
    // if the field value is incorrect then fix it
    if (![self.redField matchesRegex:ICL_Regex_RGB]) {
        [self.redField setText:[NSString stringWithFormat:@"%d", [self.redField.text intValue]]];
    }
    
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    currentRed = [self.redField.text intValue] / 255.0f;
    _workingColour = [UIColor colorWithRed:currentRed green:currentGreen blue:currentBlue alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (void)greenFieldChanged:(NSNotification*) inNotification {
    // if the field value is incorrect then fix it
    if (![self.greenField matchesRegex:ICL_Regex_RGB]) {
        [self.greenField setText:[NSString stringWithFormat:@"%d", [self.greenField.text intValue]]];
    }
    
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    currentGreen = [self.greenField.text intValue] / 255.0f;
    _workingColour = [UIColor colorWithRed:currentRed green:currentGreen blue:currentBlue alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (void)blueFieldChanged:(NSNotification*) inNotification {
    // if the field value is incorrect then fix it
    if (![self.blueField matchesRegex:ICL_Regex_RGB]) {
        [self.blueField setText:[NSString stringWithFormat:@"%d", [self.blueField.text intValue]]];
    }
    
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    currentBlue = [self.blueField.text intValue] / 255.0f;
    _workingColour = [UIColor colorWithRed:currentRed green:currentGreen blue:currentBlue alpha:currentAlpha];
    [self updateForCurrentColour];
}

- (void)updateForCurrentColour {
    // Extract the red, green, blue and alpha components and update the display
    CGFloat currentRed, currentGreen, currentBlue, currentAlpha;
    [_workingColour getRed:&currentRed green:&currentGreen blue:&currentBlue alpha:&currentAlpha];
    
    [self.redField setText:[NSString stringWithFormat:@"%d", (int)(currentRed * 255)]];
    [self.greenField setText:[NSString stringWithFormat:@"%d", (int)(currentGreen * 255)]];
    [self.blueField setText:[NSString stringWithFormat:@"%d", (int)(currentBlue * 255)]];
    
    // Extract the hue, saturation and brightness and update the wheel and sliders
    CGFloat currentHue, currentSaturation, currentBrightness;
    [_workingColour getHue:&currentHue saturation:&currentSaturation brightness:&currentBrightness alpha:&currentAlpha];
    
    [self setColourWheelColour:currentHue saturation:currentSaturation];
    
    [self updateValueImage];
    
    [self setGradientBar:currentBrightness imageView:self.brightnessSelector baseImage:_valueImage];
    [self setGradientBar:currentRed imageView:self.redSelector baseImage:_redSliderImage];
    [self setGradientBar:currentGreen imageView:self.greenSelector baseImage:_greenSliderImage];
    [self setGradientBar:currentBlue imageView:self.blueSelector baseImage:_blueSliderImage];
}

- (void)updateValueImage {
    CGFloat currentHue, currentSaturation, currentBrightness, currentAlpha;
    [_workingColour getHue:&currentHue saturation:&currentSaturation brightness:&currentBrightness alpha:&currentAlpha];
    
    // Value slider starts at the current colour with the brightness at 0
    UIColor* valueStartColour = [UIColor colorWithHue:currentHue saturation:currentSaturation brightness:0.0f alpha:1.0f];
    CGFloat startRed, startGreen, startBlue, startAlpha;
    [valueStartColour getRed:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha];
    
    // Value slider ends at the current colour with the brightness at full
    UIColor* valueEndColour = [UIColor colorWithHue:currentHue saturation:currentSaturation brightness:1.0f alpha:1.0f];
    CGFloat endRed, endGreen, endBlue, endAlpha;
    [valueEndColour getRed:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha];
    
    // Generate the 0-255 RGBA equivalent
    PixelRGBA startColour = {(int)(startRed * 255), (int)(startGreen * 255), (int)(startBlue * 255), (int)(startAlpha * 255)};
    PixelRGBA endColour = {(int)(endRed * 255), (int)(endGreen * 255), (int)(endBlue * 255), (int)(endAlpha * 255)};
    
    // Update the value image
    _valueImage = [self createGradientBitmap:self.brightnessSelector.frame startColour:startColour endColour:endColour borderSize:5];
}

- (void)setColourWheelColour:(float) inCurrentHue saturation:(float) inCurrentSaturation {
    CGFloat width = self.colourWheelView.image.size.width;
    CGFloat height = self.colourWheelView.image.size.height;
    
    CGRect imageFrame = CGRectMake(0, 0, width, height);
    
    CGPoint wheelPoint = [self pointFromHueAndSaturation:inCurrentHue saturation:inCurrentSaturation wheelRect:imageFrame wheelRadius:_colourWheelRadius * _colourWheelImageScale];

    // setup the context so we can modify the image
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
  
    // draw the base version of the wheel
    [_colourWheelImage drawInRect:imageFrame];
    
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
   
    const int circleRadius = 10.0f * _colourWheelImageScale;
    CGRect circleRect = CGRectMake(wheelPoint.x - (circleRadius * 0.5f),
                                   wheelPoint.y - (circleRadius * 0.5f),
                                   circleRadius,
                                   circleRadius);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // calculate the maximum size for drawing the current colour rect
    CGFloat halfWidth = width * 0.5f;
    CGFloat halfHeight = height * 0.5f;
    CGFloat maxDiagonal = 0.75f * (sqrtf((halfWidth * halfWidth) + (halfHeight * halfHeight)) - (_colourWheelRadius * _colourWheelImageScale));
    CGFloat rectSize = maxDiagonal / sqrtf(2.0f);

    // overlay a border
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 2.0f);
    CGContextStrokeRect(context, CGRectMake(0, 0, rectSize, rectSize));
    
    // draw the current colour
    CGContextSetFillColorWithColor(context, _workingColour.CGColor);
    CGContextFillRect(context, CGRectMake(1, 1, rectSize - 1, rectSize - 1));
    
    CGContextFlush(context);
    
    UIGraphicsPopContext();
    
    self.colourWheelView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

- (void)setGradientBar:(float) inValue imageView:(UIImageView*) inImageView baseImage:(UIImage*) inBaseImage {
    CGFloat width = inImageView.image.size.width;
    CGFloat height = inImageView.image.size.height;
    
    CGRect imageFrame = CGRectMake(0, 0, width, height);
    
    // setup the context so we can modify the image
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    // draw the base version of the wheel
    [inBaseImage drawInRect:imageFrame];
    
    CGPoint startLocation = CGPointMake(width * inValue, 0);
    CGPoint endLocation = CGPointMake(width * inValue, height);
    
    CGContextSetLineWidth(context, width * 0.02f);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, startLocation.x, startLocation.y);
    CGContextAddLineToPoint(context, endLocation.x, endLocation.y);
    CGContextStrokePath(context);
    
    UIGraphicsPopContext();
    
    inImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

- (void)viewDidLayoutSubviews {
    [self updateColourWheelRadius];
    [self updateForCurrentColour];
}

@end

#endif // TARGET_OS_IPHONE