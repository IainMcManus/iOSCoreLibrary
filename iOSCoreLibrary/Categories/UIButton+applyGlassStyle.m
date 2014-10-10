//
//  UIButton+applyGlassStyle.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 8/02/13.
//
//

#import "UIButton+applyGlassStyle.h"
#import "UIColor+extensions.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIButton (applyGlassStyle)

- (void) applyGlassStyle:(GlassButtonSize) inButtonSize colour:(UIColor*) inColour {
    [self applyGlassStyle:inButtonSize colour:inColour autoColourText:NO];
}

- (void) applyGlassStyle:(GlassButtonSize) inButtonSize colour:(UIColor*) inColour autoColourText:(BOOL) autoColourText {
    if (inButtonSize == egbsNone) {
        [self setBackgroundColor:inColour];
    }
    else {
        CALayer* buttonLayer = self.layer;
        
        float cornerRadius = 0.0f;
        float borderWidth = 0.0f;
        
        // If the device running iOS version < 7 then use rounded corners
        if (!Using_iOS7OrAbove) {
            if (inButtonSize == egbsSmall) {
                cornerRadius = 4.0f;
                borderWidth = 1.0f;
            }
            else if (inButtonSize == egbsMedium) {
                cornerRadius = 8.0f;
                borderWidth = 2.0f;
            }
            else if (inButtonSize == egbsLarge) {
                cornerRadius = 16.0f;
                borderWidth = 4.0f;
            }
        }
        
        // Setup the border
        buttonLayer.cornerRadius = cornerRadius;
        buttonLayer.masksToBounds = NO;
        buttonLayer.borderWidth = borderWidth;
        buttonLayer.borderColor = inColour.CGColor;
        
        // Need to add a shadow otherwise the button looks bad but it may not be supported so check first
        if ([buttonLayer respondsToSelector:@selector(shadowOpacity)])
        {
            buttonLayer.shadowOpacity = 0.7;
            buttonLayer.shadowColor = [[UIColor blackColor] CGColor];
            buttonLayer.shadowOffset = CGSizeMake(0.0, 3.0);
            
            if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2)
            {
                buttonLayer.rasterizationScale = 2.0;
            }
            
            buttonLayer.shouldRasterize = YES;
        }
        
        // If we already have a background layer then grab it, otherwise create it
        CALayer* backgroundLayer = nil;
        BOOL createdBackgroundLayer = NO;
        NSUInteger layerIndex = 0;
        for (CALayer* subLayer in [buttonLayer sublayers]) {
            if ([subLayer.name isEqualToString:@"UIButton+applyGlassStyle:Background"]) {
                backgroundLayer = subLayer;
                break;
            }
            ++layerIndex;
        }
        
        // never found the layer so create a new one
        if (!backgroundLayer ) {
            backgroundLayer = [CALayer layer];
            backgroundLayer.name = @"UIButton+applyGlassStyle:Background";
            createdBackgroundLayer = YES;
        } // if the layer is not in the background then move it
        else if (layerIndex != 0) {
            [backgroundLayer removeFromSuperlayer];
            [buttonLayer insertSublayer:backgroundLayer atIndex:0];
        }
        
        // Configure the background layer
        backgroundLayer.cornerRadius = cornerRadius;
        backgroundLayer.masksToBounds = YES;
        backgroundLayer.frame = buttonLayer.bounds;
        backgroundLayer.backgroundColor = inColour.CGColor;
        
        if (createdBackgroundLayer) {
            [buttonLayer insertSublayer:backgroundLayer atIndex:0];
        }
        
        // We want the original background layer to be clear
        buttonLayer.backgroundColor = [UIColor clearColor].CGColor;
        
        CAGradientLayer* glossLayer = nil;
        BOOL createdGlossLayer = NO;
        layerIndex = 0;
        for (CALayer* subLayer in [backgroundLayer sublayers]) {
            if ([subLayer.name isEqualToString:@"UIButton+applyGlassStyle:Gloss"]) {
                glossLayer = (CAGradientLayer*)subLayer;
                break;
            }
            ++layerIndex;
        }
        
        if (!glossLayer) {
            glossLayer = [CAGradientLayer layer];
            glossLayer.name = @"UIButton+applyGlassStyle:Gloss";
            createdGlossLayer = YES;
        }
        else if (layerIndex != 0) {
            [glossLayer removeFromSuperlayer];
            [backgroundLayer insertSublayer:glossLayer atIndex:0];
        }
        
        // Configure the glossy layer
        glossLayer.frame = buttonLayer.bounds;
        glossLayer.colors = @[(id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                              (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                              (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                              (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                              (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor];
        glossLayer.locations = @[@0.0f,
                                 @0.5f,
                                 @0.5f,
                                 @0.8f,
                                 @1.0f];
        
        if (createdGlossLayer) {
            [backgroundLayer addSublayer:glossLayer];
        }
        
        // if there was an image then remove and re-add to force a redraw
        if (self.imageView && self.imageView.layer) {
            CALayer* imageLayer = self.imageView.layer;
            
            [self.imageView.layer removeFromSuperlayer];
            
            [buttonLayer addSublayer:imageLayer];
        }
    }
    
    if (autoColourText) {
        if ([inColour perceivedBrightness] < 0.5f) {
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        else {
            [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }
}

@end
