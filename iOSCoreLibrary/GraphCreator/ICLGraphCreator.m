//
//  ICLGraphCreator.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 19/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLGraphCreator.h"

#import "UIColor+Extensions.h"

#import <UIKit/UIKit.h>

NSString* kICLWidthKey = @"Width";
NSString* kICLHeightKey = @"Height";
NSString* kICLDataColours = @"DataColours";
NSString* kICLMaximumColour = @"MaximumColour";
NSString* kICLFontSize = @"FontSize";
NSString* kICLFontSize_LegendLabel = @"FontSize.Legend";
NSString* kICLNumLabelsAcrossForLegend = @"NumLabelsAcrossForLegend";
NSString* kICLCategoryColours = @"Category.Colours";
NSString* kICLCategoryOrders = @"Category.Orders";

NSString* kICLMarginLeft = @"MarginLeft";
NSString* kICLMarginRight = @"MarginRight";
NSString* kICLMarginTop = @"MarginTop";
NSString* kICLMarginBottom = @"MarginBotton";
NSString* kICLLegendHeight = @"LegendHeight";

NSString* kICLAxisWidth = @"AxisWidth";

NSString* kICLValueLabels = @"ValueLabels";
NSString* kICLXAxisLabels = @"XAxisLabels";
NSString* kICLYAxisLabels = @"YAxisLabels";

NSString* kICLMaximumValue = @"MaximumValue";

@implementation ICLGraphCreator

// Normalise an angle into 0-360 range
+ (CGFloat) normalisedAngle:(CGFloat) angle {
    return angle - (floor(angle / (M_PI * 2.0)) * 2.0 * M_PI);
}

// Helper method to handle testing if an angle is between two other angles with
// proper handling for negative angles
+ (BOOL) isBetween:(CGFloat) angle start:(CGFloat) startAngle end:(CGFloat) endAngle {
    CGFloat normalisedAngle = [self normalisedAngle:angle];
    CGFloat normalisedStartAngle = [self normalisedAngle:startAngle];
    
    if (normalisedAngle < [self normalisedAngle:startAngle]) {
        return NO;
    }
    
    CGFloat normalisedEndAngle = [self normalisedAngle:endAngle];
    
    if (normalisedEndAngle < normalisedStartAngle) {
        normalisedEndAngle += 2.0f * M_PI;
    }
    
    if (normalisedAngle > normalisedEndAngle) {
        return NO;
    }
    
    return YES;
}

+ (UIImage*) createGraph:(ICLGraphType) type
                  labels:(NSDictionary*) labels
                  values:(NSArray*) values
            valueStrings:(NSArray*) valueStrings
              attributes:(NSDictionary*) attributes
     showLegendForHidden:(BOOL) showLegendForHidden {
    // Dispatch based on the graph type
    switch(type) {
        case iclgtPieChart: {
            return [self createGraph_PieChart:labels
                                       values:values
                                 valueStrings:valueStrings
                                   attributes:attributes
                                       hollow:NO
                          showLegendForHidden:showLegendForHidden];
        }
            
        case iclgtHollowPieChart: {
            return [self createGraph_PieChart:labels
                                       values:values
                                 valueStrings:valueStrings
                                   attributes:attributes
                                       hollow:YES
                          showLegendForHidden:showLegendForHidden];
        }
            
        case iclgtBarGraph: {
            return [self createGraph_BarGraph:labels
                                       values:values
                                 valueStrings:valueStrings
                                   attributes:attributes];
        }
            
        case iclgtLineGraph: {
            return [self createGraph_LineGraph:labels
                                        values:values
                                    attributes:attributes];
        }
            
        case iclgtStackedBarGraph: {
            return [self createGraph_StackedBarGraph:labels
                                              values:values
                                          attributes:attributes];
        }
    }

    return nil;
}

+ (UIImage*) createGraph_PieChart:(NSDictionary*) labels
                           values:(NSArray*) values
                     valueStrings:(NSArray*) valueStrings
                       attributes:(NSDictionary*) attributes
                           hollow:(BOOL) hollow
             showLegendForHidden:(BOOL) showLegendForHidden {
    if ([values count] == 0) {
        return nil;
    }
    
    CGFloat width = attributes[kICLWidthKey] ? [attributes[kICLWidthKey] floatValue] : 320.0f;
    CGFloat height = attributes[kICLHeightKey] ? [attributes[kICLHeightKey] floatValue] : 320.0f;
    
    CGPoint origin = CGPointMake(width / 2.0f, height / 2.0f);
    CGFloat maximumRadius = MIN(width / 2.0f, height / 2.0f) * 0.95f;
    
    CGFloat arcWidth = hollow ? (maximumRadius * 0.75f) : maximumRadius;
    CGFloat radius = hollow ? (maximumRadius - (arcWidth / 2.0f)) : maximumRadius * 0.5f;

    // calculate the sum of all the data values
    __block double sumOfAllValues = 0;
    [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        sumOfAllValues += [obj doubleValue];
    }];
    
    // generate normalised values array with each value corresponding to the sector angle in radians
    NSMutableArray* normalisedValues = [[NSMutableArray alloc] initWithCapacity:[values count]];
    double scaleFactor = sumOfAllValues == 0 ? 0 : (M_PI * 2.0f) / sumOfAllValues;
    for (NSNumber* value in values) {
        [normalisedValues addObject:@(scaleFactor * [value doubleValue])];
    }
    
    UIImage* image = nil;
    
    NSArray* valueLabels = labels[kICLValueLabels];
    
    @autoreleasepool {
        // setup the context so we can modify the image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        double hueIncrement = 1.0f / ((double) [normalisedValues count] + 1);
        double currentHue = 0;
        
        NSMutableDictionary* coloursForData = [[NSMutableDictionary alloc] initWithCapacity:[values count]];
        if (attributes[kICLDataColours]) {
            NSDictionary* providedColours = attributes[kICLDataColours];
            
            for (NSString* key in valueLabels) {
                // if the existing colour is valid then use it
                if (providedColours[key] && [providedColours[key] isKindOfClass:[UIColor class]]) {
                    coloursForData[key] = providedColours[key];
                } // otherwise autogenerate a colour
                else {
                    coloursForData[key] = [UIColor colorWithHue:currentHue saturation:0.5f brightness:0.85f alpha:1.0f];
                    currentHue += hueIncrement;
                }
            }
        } // no colours provided so autogenerate
        else {
            for (NSString* key in valueLabels) {
                coloursForData[key] = [UIColor colorWithHue:currentHue saturation:0.5f brightness:0.85f alpha:1.0f];
                currentHue += hueIncrement;
            }
        }

        CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();

        // draw the graph wedges
        __block double angleOffset = -M_PI_2;
        [valueLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIColor* colour = (UIColor*)coloursForData[obj];
            
            double normalisedValue = [normalisedValues[idx] doubleValue];

            UIBezierPath* arc = [UIBezierPath bezierPathWithArcCenter:origin
                                                               radius:radius
                                                           startAngle:angleOffset
                                                             endAngle:angleOffset + normalisedValue
                                                            clockwise:YES];
            
            CGPathRef shape = CGPathCreateCopyByStrokingPath(arc.CGPath, NULL, arcWidth, kCGLineCapButt, kCGLineJoinMiter, 10.0f);
            
            // Draw the gradient wedge
            CGContextSaveGState(context);
            
            CGContextBeginPath(context);
            CGContextAddPath(context, shape);
            
            CGContextClip(context);
            
            CGFloat locations[] = { 1.0, 0.0f };
            NSArray *colours = @[(__bridge id) colour.CGColor,
                                 (__bridge id) [colour autoGenerateLighterShade].CGColor];
            
            CGGradientRef gradient = CGGradientCreateWithColors(colourSpace, (__bridge CFArrayRef) colours, locations);
            CGContextDrawRadialGradient(context, gradient, origin, 0, origin, maximumRadius, 0);
            
            CGGradientRelease(gradient);
            CGContextRestoreGState(context);
            
            // Draw the outline of the wedge
            CGContextBeginPath(context);
            CGContextAddPath(context, shape);
            
            CGContextSetStrokeColorWithColor(context, [colour autoGenerateDifferentShade].CGColor);
            CGContextSetLineWidth(context, 1.0f);
            CGContextStrokePath(context);

            CGPathRelease(shape);

            angleOffset += normalisedValue;
        }];
        
        CGColorSpaceRelease(colourSpace);
        
        CGFloat pieChartFontSize = attributes[kICLFontSize] ? [attributes[kICLFontSize] floatValue] : 24.0f;
        UIFont* pieChartLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:pieChartFontSize];
        
        CGFloat legendFontSize = attributes[kICLFontSize_LegendLabel] ? [attributes[kICLFontSize_LegendLabel] floatValue] : 12.0f;
        UIFont* legendLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:legendFontSize];
        
        const NSString* kMissingText_Colour = @"MissingText.Colour";
        const NSString* kMissingText_Label = @"MissingText.Label";
        const NSString* kMissingText_Value = @"MissingText.Value";
        
        __block CGFloat widestText = 0;
        __block CGFloat highestText = 0;
        
        NSMutableArray* missingText = [[NSMutableArray alloc] initWithCapacity:[labels count]];
        
        // reset the angle and draw the text. we do this last so the text is always on top of the wedges
        angleOffset = -M_PI_2;
        [valueLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            double normalisedValue = [normalisedValues[idx] doubleValue];

            UIColor* colour = (UIColor*)coloursForData[obj];
            
            // auto select the colour based on the perceived brightness
            CGColorRef cgColour;
            if ([colour perceivedBrightness] < 0.5f) {
                cgColour = [UIColor whiteColor].CGColor;
            }
            else {
                cgColour = [UIColor blackColor].CGColor;
            }
            
            NSString* labelString = obj;
            CGSize labelStringSize = [labelString sizeWithFont:pieChartLabelFont];
            
            NSString* valueString = valueStrings[idx];
            CGSize valueStringSize = [valueString sizeWithFont:pieChartLabelFont];
            
            // Determine the size of the label and value combined
            CGSize textSize = CGSizeMake(MAX(labelStringSize.width, valueStringSize.width),
                                         labelStringSize.height + valueStringSize.height + 5);

            // Store the cosine and sine of the center angle for later use
            double cosAngle = cos(angleOffset + normalisedValue * 0.5f);
            double sinAngle = sin(angleOffset + normalisedValue * 0.5f);
            
            CGFloat xOffset = origin.x + (radius * cosAngle);
            CGFloat yOffset = origin.y + (radius * sinAngle);
            
            // Work out the final text rect
            CGRect textRect = CGRectMake(xOffset - textSize.width * 0.5f,
                                         yOffset - textSize.height * 0.5f,
                                         textSize.width,
                                         textSize.height);
            
            // Assume the text fits
            BOOL textFits = YES;

            // Test the angle to every point and ensure they all fit
            double angleBias = M_PI * 0.5f;
            double startAngle = angleOffset + angleBias;
            double endAngle = startAngle + normalisedValue;
            double angleToTopLeft = atan2(textRect.origin.y - origin.y,
                                          textRect.origin.x - origin.x) + angleBias;
            if (![self isBetween:angleToTopLeft start:startAngle end:endAngle]) {
                textFits = NO;
            }
            else {
                double angleToTopRight = atan2(textRect.origin.y - origin.y,
                                               textRect.origin.x - origin.x + textRect.size.width) + angleBias;
                if (![self isBetween:angleToTopRight start:startAngle end:endAngle]) {
                    textFits = NO;
                }
                else {
                    double angleToBottomLeft = atan2(textRect.origin.y - origin.y + textRect.size.height,
                                                     textRect.origin.x - origin.x) + angleBias;
                    if (![self isBetween:angleToBottomLeft start:startAngle end:endAngle]) {
                        textFits = NO;
                    }
                    else {
                        double angleToBottomRight = atan2(textRect.origin.y - origin.y + textRect.size.height,
                                                          textRect.origin.x - origin.x + textRect.size.width) + angleBias;
                        if (![self isBetween:angleToBottomRight start:startAngle end:endAngle]) {
                            textFits = NO;
                        }
                    }
                }
            }
            
            // Only draw the text if it will fit
            if (textFits) {
                CGContextSaveGState(context);
                CGContextSetFillColorWithColor(context, cgColour);
                
                [labelString drawInRect:textRect
                               withFont:pieChartLabelFont
                          lineBreakMode:NSLineBreakByClipping
                              alignment:NSTextAlignmentCenter];
                
                textRect.origin = CGPointMake(textRect.origin.x, textRect.origin.y + labelStringSize.height + 5);
                [valueString drawInRect:textRect
                               withFont:pieChartLabelFont
                          lineBreakMode:NSLineBreakByClipping
                              alignment:NSTextAlignmentCenter];
                
                CGContextRestoreGState(context);
            }
            else if (showLegendForHidden) {
                widestText = MAX(widestText, textSize.width);
                highestText = MAX(highestText, textSize.height);
                
                [missingText addObject:@{kMissingText_Colour: colour,
                                         kMissingText_Label: labelString,
                                         kMissingText_Value: valueString}];
            }
            
            angleOffset += normalisedValue;
        }];
        
        // If text is missing then draw the legend
        if ([missingText count] > 0) {
            CGFloat marginLeft   = attributes[kICLMarginLeft]   ? [attributes[kICLMarginLeft] floatValue]   : 20.0f;
            CGFloat marginRight  = attributes[kICLMarginRight]  ? [attributes[kICLMarginRight] floatValue]  : 20.0f;
            CGFloat marginBottom = attributes[kICLMarginBottom] ? [attributes[kICLMarginBottom] floatValue] : 20.0f;
            CGFloat marginTop = attributes[kICLMarginTop] ? [attributes[kICLMarginTop] floatValue] : 20.0f;
            
            CGFloat horizontalMargin = (marginLeft + marginRight) / 2.0;
            CGFloat verticalMargin = (marginTop + marginBottom) / 2.0;
            
            CGFloat labelWidth = widestText + horizontalMargin;
            CGFloat labelHeight = highestText + verticalMargin;
            
            __block NSUInteger numLabelsPerRow = attributes[kICLNumLabelsAcrossForLegend] ? [attributes[kICLNumLabelsAcrossForLegend] integerValue] : 4;
            NSUInteger numLabels = [missingText count];
            NSUInteger numRows = MAX(1, (numLabels + (numLabelsPerRow - (numLabels % numLabelsPerRow))) / numLabelsPerRow);
            
            CGFloat heightRequired = numRows * (labelHeight + verticalMargin);
            
            CGFloat mostLabelsAcross = numLabels >= numLabelsPerRow ? numLabelsPerRow : (numLabels % numLabelsPerRow);
            CGFloat usedWidth = mostLabelsAcross * (labelWidth + horizontalMargin) - horizontalMargin;

            CGSize originalLabelSize = CGSizeMake(MAX(usedWidth + marginLeft + marginRight, width), heightRequired);

            // Create a fresh context for the labels
            UIGraphicsBeginImageContextWithOptions(originalLabelSize, NO, 1.0);
            CGContextRef labelContext = UIGraphicsGetCurrentContext();
            UIGraphicsPushContext(labelContext);

            // Draw the labels
            
            __block CGFloat blockOriginX = originalLabelSize.width < usedWidth ? marginLeft : ((originalLabelSize.width - usedWidth) / 2);
            __block CGFloat blockOriginY = 0;
            
            __block CGFloat workingX = blockOriginX;
            __block CGFloat workingY = blockOriginY;
            
            [missingText enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                UIColor* colour = obj[kMissingText_Colour];
                
                CGRect labelRect = CGRectMake(workingX, workingY, labelWidth, labelHeight);
                
                // Draw the block for the label
                CGContextSaveGState(labelContext);
                CGContextSetFillColorWithColor(labelContext, colour.CGColor);
                CGContextFillRect(labelContext, labelRect);
                CGContextFlush(labelContext);
                CGContextRestoreGState(labelContext);
                
                NSString* labelString = obj[kMissingText_Label];
                CGSize labelStringSize = [labelString sizeWithFont:legendLabelFont];
                
                NSString* valueString = obj[kMissingText_Value];
                CGSize valueStringSize = [valueString sizeWithFont:legendLabelFont];
                
                // Determine the size of the label and value combined
                CGSize textSize = CGSizeMake(MAX(labelStringSize.width, valueStringSize.width),
                                             labelStringSize.height + valueStringSize.height + 5);
                
                // Work out the final text rect
                CGRect textRect = CGRectMake(workingX + (labelWidth - textSize.width) / 2,
                                             workingY + (labelHeight - textSize.height) / 2,
                                             textSize.width,
                                             textSize.height);
                
                // auto select the colour based on the perceived brightness
                CGColorRef cgColour;
                if ([colour perceivedBrightness] < 0.5f) {
                    cgColour = [UIColor whiteColor].CGColor;
                }
                else {
                    cgColour = [UIColor blackColor].CGColor;
                }
                
                CGContextSaveGState(labelContext);
                CGContextSetFillColorWithColor(labelContext, cgColour);
                
                [labelString drawInRect:textRect
                               withFont:legendLabelFont
                          lineBreakMode:NSLineBreakByClipping
                              alignment:NSTextAlignmentCenter];
                
                textRect.origin = CGPointMake(textRect.origin.x, textRect.origin.y + labelStringSize.height + 5);
                [valueString drawInRect:textRect
                               withFont:legendLabelFont
                          lineBreakMode:NSLineBreakByClipping
                              alignment:NSTextAlignmentCenter];
                
                CGContextRestoreGState(labelContext);
                
                if ((idx + 1) % numLabelsPerRow == 0) {
                    workingX = blockOriginX;
                    workingY += verticalMargin + labelHeight;
                }
                else {
                    workingX += horizontalMargin + labelWidth;
                }
            }];
            
            // Flush the context and retrieve the label
            CGContextFlush(labelContext);
            UIGraphicsPopContext();
            UIImage* labelImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // Flush the context and retrieve the pie chart
            CGContextFlush(context);
            UIGraphicsPopContext();
            UIImage* pieChartImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // Setup a new context for the combined image
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            UIGraphicsPushContext(context);
            
            CGSize newLabelSize = originalLabelSize;
            
            // label is too wide so rescale
            if (originalLabelSize.width > width) {
                newLabelSize = CGSizeMake(width, (originalLabelSize.height / originalLabelSize.width) * width);
            }
            
            CGRect labelRect, pieChartRect;
            
            // If the graph is wider than it is tall then we may need to shrink it
            if (width > height) {
                // If the label block is taking up less than 25% of the height then preserve it's height
                if ((newLabelSize.height / height) < 0.25f) {
                    labelRect = CGRectMake(0, height - marginBottom - newLabelSize.height, width, newLabelSize.height);
                }
                else {
                    CGFloat newHeight = height * 0.25f;
                    CGFloat newWidth = (width / newLabelSize.height) * newHeight;
                    labelRect = CGRectMake((width - newWidth) / 2,
                                           height - marginBottom - newHeight,
                                           newWidth,
                                           newHeight);
                }
                
                CGFloat newHeight = labelRect.origin.y - marginTop - marginBottom;
                CGFloat newWidth = (width / height) * newHeight;
                pieChartRect = CGRectMake((width - newWidth) / 2,
                                          marginTop,
                                          newWidth,
                                          newHeight);
            } // If the graph is taller than it is high we may have enough room without shrinking it too much
            else {
                CGFloat availableHeight = height - origin.y - maximumRadius;
                
                // Is the required label height less than our spare height?
                if (newLabelSize.height < availableHeight) {
                    labelRect = CGRectMake(0, height - marginBottom - newLabelSize.height, width, newLabelSize.height);
                    
                    pieChartRect = CGRectMake(0,
                                              0,
                                              width,
                                              height);
                } // Otherwise we don't have enough space and need to shrink the graph and label
                else {
                    CGFloat newHeight = MIN(height * 0.25f, newLabelSize.height);
                    CGFloat newWidth = (width / newLabelSize.height) * newHeight;
                    labelRect = CGRectMake((width - newWidth) / 2,
                                           height - marginBottom - newHeight,
                                           newWidth,
                                           newHeight);
                    
                    newHeight = labelRect.origin.y - marginTop - marginBottom;
                    newWidth = (width / height) * newHeight;
                    pieChartRect = CGRectMake((width - newWidth) / 2,
                                              marginTop,
                                              newWidth,
                                              newHeight);
                }
            }
            
            // Redraw the label and pie chart
            [pieChartImage drawInRect:pieChartRect blendMode:kCGBlendModeCopy alpha:1.0];
            [labelImage drawInRect:labelRect blendMode:kCGBlendModeCopy alpha:1.0];
        }

        UIGraphicsPopContext();
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

+ (UIImage*) createGraph_BarGraph:(NSDictionary*) labels
                           values:(NSArray*) values
                     valueStrings:(NSArray*) valueStrings
                       attributes:(NSDictionary*) attributes {
    if ([values count] == 0) {
        return nil;
    }
    
    CGFloat width        = attributes[kICLWidthKey]     ? [attributes[kICLWidthKey] floatValue]     : 320.0f;
    CGFloat height       = attributes[kICLHeightKey]    ? [attributes[kICLHeightKey] floatValue]    : 320.0f;
    CGFloat marginLeft   = attributes[kICLMarginLeft]   ? [attributes[kICLMarginLeft] floatValue]   : 20.0f;
    CGFloat marginRight  = attributes[kICLMarginRight]  ? [attributes[kICLMarginRight] floatValue]  : 20.0f;
    CGFloat marginTop    = attributes[kICLMarginTop]    ? [attributes[kICLMarginTop] floatValue]    : 10.0f;
    CGFloat marginBottom = attributes[kICLMarginBottom] ? [attributes[kICLMarginBottom] floatValue] : 70.0f;
    CGFloat axisWidth    = attributes[kICLAxisWidth]    ? [attributes[kICLAxisWidth] floatValue]    : 2.0f;
    
    CGFloat maximumHeight = height - (marginTop + marginBottom);
    CGFloat maximumWidth = width - (marginLeft + marginRight);
    CGFloat barWithMarginWidth = maximumWidth / [values count];
    CGFloat barWidth = barWithMarginWidth * 0.75f;
    CGFloat barMarginWidth = barWithMarginWidth * 0.25f;
    
    // calculate the sum of all the data values
    __block double highestValue = 0;
    [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        highestValue = MAX(highestValue, [obj doubleValue]);
    }];
    
    // normalise the data
    NSMutableArray* normalisedValues = [[NSMutableArray alloc] initWithCapacity:[values count]];
    double scaleFactor = highestValue == 0 ? 0 : (maximumHeight - marginBottom) / highestValue;
    for (NSNumber* value in values) {
        [normalisedValues addObject:@(scaleFactor * [value doubleValue])];
    }
    
    UIImage* image = nil;
    
    NSArray* valueLabels = labels[kICLValueLabels];
    
    @autoreleasepool {
        // setup the context so we can modify the image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        double hueIncrement = 1.0f / ((double) [normalisedValues count] + 1);
        double currentHue = 0;
        
        NSMutableDictionary* coloursForData = [[NSMutableDictionary alloc] initWithCapacity:[values count]];
        if (attributes[kICLDataColours]) {
            NSDictionary* providedColours = attributes[kICLDataColours];
            
            for (NSString* key in valueLabels) {
                // if the existing colour is valid then use it
                if (providedColours[key] && [providedColours[key] isKindOfClass:[UIColor class]]) {
                    coloursForData[key] = providedColours[key];
                } // otherwise autogenerate a colour
                else {
                    coloursForData[key] = [UIColor colorWithHue:currentHue saturation:0.5f brightness:0.85f alpha:1.0f];
                    currentHue += hueIncrement;
                }
            }
        } // no colours provided so autogenerate
        else {
            for (NSString* key in valueLabels) {
                coloursForData[key] = [UIColor colorWithHue:currentHue saturation:0.5f brightness:0.85f alpha:1.0f];
                currentHue += hueIncrement;
            }
        }
        
        CGFloat fontSize = attributes[kICLFontSize] ? [attributes[kICLFontSize] floatValue] : 12.0f;
        UIFont* textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:fontSize];
        
        CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
        
        // draw all of the bars
        __block CGFloat xOffset = marginLeft + barMarginWidth * 0.5f;
        [valueLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIColor* colour = (UIColor*)coloursForData[obj];
            CGFloat barHeight = [normalisedValues[idx] floatValue];
            
            CGRect barRect = CGRectMake(xOffset, marginTop + (maximumHeight - barHeight), barWidth, barHeight);

            CGFloat locations[] = { 1.0, 0.0f };
            NSArray *colours = @[(__bridge id) colour.CGColor,
                                 (__bridge id) [colour autoGenerateLighterShade].CGColor];
            
            CGPoint barStart = CGPointMake(xOffset, marginTop + (maximumHeight - barHeight));
            CGPoint barEnd = CGPointMake(xOffset, marginTop + maximumHeight);
            
            CGContextSaveGState(context);
            CGContextClipToRect(context, barRect);
            
            // Draw the gradient bar
            CGGradientRef gradient = CGGradientCreateWithColors(colourSpace, (__bridge CFArrayRef) colours, locations);
            CGContextDrawLinearGradient(context, gradient, barStart, barEnd, 0);
            
            CGGradientRelease(gradient);
            CGContextRestoreGState(context);
            
            // calculate the size and location of the bar label
            NSString* labelString = obj;
            CGSize textSize = [labelString sizeWithFont:textFont];

            // Only draw the labels if there is sufficient room
            if (textSize.height < barRect.size.width) {
                CGRect textRect = CGRectMake(xOffset,
                                             marginTop + maximumHeight,
                                             textSize.width,
                                             textSize.height);
                
                // draw the lower bar label
                CGContextSaveGState(context);
                CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                
                CGContextConcatCTM(context, CGAffineTransformMakeTranslation(textRect.origin.x, textRect.origin.y));
                CGContextConcatCTM(context, CGAffineTransformMakeRotation(M_PI * 0.125f));
                CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-textRect.origin.x, -textRect.origin.y));
                
                [labelString drawInRect:textRect
                               withFont:textFont
                          lineBreakMode:NSLineBreakByClipping
                              alignment:NSTextAlignmentCenter];
                
                CGContextRestoreGState(context);
                
                NSString* valueString = valueStrings[idx];
                textSize = [valueString sizeWithFont:textFont];
                
                // slightly offset the text by extending the width
                textSize.width += marginTop;
                
                // draw above/below the bar as appropriate
                CGFloat yOffset = barRect.size.height < textSize.width ? barRect.origin.y - textSize.width : barRect.origin.y;
                
                textRect = CGRectMake(xOffset + ((barWidth + textSize.height) * 0.5f),
                                      yOffset,
                                      textSize.width,
                                      textSize.height);
                
                // draw the value label
                CGContextSaveGState(context);
                CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                
                CGContextConcatCTM(context, CGAffineTransformMakeTranslation(textRect.origin.x, textRect.origin.y));
                CGContextConcatCTM(context, CGAffineTransformMakeRotation(M_PI * 0.5f));
                CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-textRect.origin.x, -textRect.origin.y));
                
                [valueString drawInRect:textRect
                               withFont:textFont
                          lineBreakMode:NSLineBreakByClipping
                              alignment:NSTextAlignmentCenter];
                
                CGContextRestoreGState(context);
            }

            xOffset += barWithMarginWidth;
        }];
        
        CGColorSpaceRelease(colourSpace);
        
        // draw the axes
        CGContextSetLineWidth(context, axisWidth);
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        
        CGContextMoveToPoint(context, marginLeft, marginTop + maximumHeight);
        CGContextAddLineToPoint(context, marginLeft + maximumWidth, marginTop + maximumHeight);
        CGContextStrokePath(context);
        
        CGContextFlush(context);
        
        UIGraphicsPopContext();
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

+ (UIImage*) createGraph_LineGraph:(NSDictionary*) labels
                            values:(NSArray*) values
                       attributes:(NSDictionary*) attributes {
    if ([values count] == 0) {
        return nil;
    }
    
    CGFloat width        = attributes[kICLWidthKey]     ? [attributes[kICLWidthKey] floatValue]     : 320.0f;
    CGFloat height       = attributes[kICLHeightKey]    ? [attributes[kICLHeightKey] floatValue]    : 320.0f;
    CGFloat marginLeft   = attributes[kICLMarginLeft]   ? [attributes[kICLMarginLeft] floatValue]   : width * 0.15f;
    CGFloat marginRight  = attributes[kICLMarginRight]  ? [attributes[kICLMarginRight] floatValue]  : width * 0.10f;
    CGFloat marginTop    = attributes[kICLMarginTop]    ? [attributes[kICLMarginTop] floatValue]    : height * 0.1f;
    CGFloat marginBottom = attributes[kICLMarginBottom] ? [attributes[kICLMarginBottom] floatValue] : height * 0.1f;
    CGFloat axisWidth    = attributes[kICLAxisWidth]    ? [attributes[kICLAxisWidth] floatValue]    : 2.0f;
    
    CGFloat maximumHeight = height - (marginTop + marginBottom);
    CGFloat maximumWidth = width - (marginLeft + marginRight);
    CGFloat pointSpacing = maximumWidth / ([values count] - 1);
    
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    // calculate the sum of all the data values
    __block double highestValue = 0;
    
    if (attributes[kICLMaximumValue]) {
        highestValue = [attributes[kICLMaximumValue] doubleValue];
    }
    else {
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            highestValue = MAX(highestValue, [obj doubleValue]);
        }];
    }
    
    // normalise the data
    NSMutableArray* normalisedValues = [[NSMutableArray alloc] initWithCapacity:[values count]];
    double scaleFactor = highestValue == 0 ? 0 : maximumHeight / highestValue;
    for (NSNumber* value in values) {
        [normalisedValues addObject:@(scaleFactor * [value doubleValue])];
    }
    
    UIImage* image = nil;
    
    @autoreleasepool {
        // setup the context so we can modify the image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGContextBeginPath(context);
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        
        // Set the starting point
        [bezierPath moveToPoint:CGPointMake(marginLeft, marginTop + maximumHeight)];

        // Add the graph points to the bezier path
        __block CGFloat xOffset = marginLeft;
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat barHeight = [normalisedValues[idx] floatValue];
            
            CGPoint point = CGPointMake(xOffset, marginTop + (maximumHeight - barHeight));
            [bezierPath addLineToPoint:point];
            
            if ((idx + 1) == [values count]) {
                [bezierPath addLineToPoint:CGPointMake(xOffset, marginTop + maximumHeight)];
            }
            
            xOffset += pointSpacing;
        }];
        
        // Setup the colour space for the gradient fill
        CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
        UIColor* colour = attributes[kICLMaximumColour] ? attributes[kICLMaximumColour] : [UIColor magentaColor];
        
        CGFloat locations[] = { 0.0, 1.0f };
        NSArray *colours = @[(__bridge id) colour.CGColor,
                             (__bridge id) [colour autoGenerateLighterShade].CGColor];
        

        CGContextSaveGState(context);
        
        // Clip to the path
        [bezierPath addClip];
        
        // Draw the gradient bar
        CGGradientRef gradient = CGGradientCreateWithColors(colourSpace, (__bridge CFArrayRef) colours, locations);
        CGContextDrawLinearGradient(context,
                                    gradient,
                                    CGPointMake(marginLeft, marginTop + maximumHeight),
                                    CGPointMake(marginLeft, marginTop),
                                    0);
        
        CGGradientRelease(gradient);
        CGContextRestoreGState(context);
        CGColorSpaceRelease(colourSpace);
        
        // Draw the path
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        [bezierPath setLineWidth:1.0f];
        [bezierPath stroke];
        
        // Add the lines to the points
        xOffset = marginLeft;
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGFloat barHeight = [normalisedValues[idx] floatValue];
            CGPoint point = CGPointMake(xOffset, marginTop + (maximumHeight - barHeight));
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, point.x, marginTop + maximumHeight);
            CGContextAddLineToPoint(context, point.x, point.y);

            CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextSetLineWidth(context, 1.0f);
            
            CGContextStrokePath(context);
            
            CGFloat elipseSize = MIN(width, height) * 0.01;
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(point.x - (elipseSize * 0.5f),
                                                           point.y - (elipseSize * 0.5f),
                                                           elipseSize,
                                                           elipseSize));

            xOffset += pointSpacing;
        }];
        
        // Draw the axes
        CGContextSetLineWidth(context, axisWidth);
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        
        CGContextMoveToPoint(context, marginLeft, marginTop);
        CGContextAddLineToPoint(context, marginLeft, marginTop + maximumHeight);
        CGContextAddLineToPoint(context, marginLeft + maximumWidth, marginTop + maximumHeight);
        CGContextStrokePath(context);
        
        // Draw the y axis labels if present
        NSArray* yAxisLabels = labels[kICLYAxisLabels];
        if ([yAxisLabels count] > 0) {
            CGFloat fontSize = attributes[kICLFontSize] ? [attributes[kICLFontSize] floatValue] : 12.0f;
            UIFont* textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:fontSize];

            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);

            // Draw the labels
            CGFloat heightIncrement = maximumHeight / ([yAxisLabels count] - 1);
            [yAxisLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CGPoint point = CGPointMake(marginLeft, marginTop + maximumHeight - (heightIncrement * idx));
                
                if (point.y < (marginTop - 0.5f)) {
                    *stop = YES;
                }
                else {
                    NSString* text = (NSString*) obj;
                    
                    CGSize textSize = [text sizeWithFont:textFont];
                    
                    CGRect textRect = CGRectMake(marginLeft - textSize.width - marginLeft * 0.075f,
                                                 marginTop + maximumHeight - (heightIncrement * idx) - (textSize.height * 0.5f),
                                                 textSize.width,
                                                 textSize.height);
                    
                    [text drawInRect:textRect withFont:textFont];
                    
                    CGContextBeginPath(context);
                    CGContextMoveToPoint(context, point.x, point.y);
                    CGContextAddLineToPoint(context, point.x - marginLeft * 0.05f, point.y);
                    
                    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
                    CGContextSetLineWidth(context, 5.0f);
                    
                    CGContextStrokePath(context);
                }
            }];
        }
        
        // Draw the x axis labels if present
        NSArray* xAxisLabels = labels[kICLXAxisLabels];
        if ([xAxisLabels count] > 0) {
            CGFloat fontSize = attributes[kICLFontSize] ? [attributes[kICLFontSize] floatValue] : 12.0f;
            UIFont* textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:fontSize];
            
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            // Draw the labels
            __block BOOL shiftDown = NO;
            __block CGRect previousRect = CGRectZero;
            __block CGFloat xOffset = marginLeft + pointSpacing * 0.5f;
            [xAxisLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString* text = (NSString*) obj;
                
                CGSize textSize = [text sizeWithFont:textFont];
                
                CGFloat yOffset = shiftDown ? marginBottom * 0.15f : 0;
                
                CGRect textRect = CGRectMake(xOffset + (pointSpacing * idx) - (textSize.width * 0.5f),
                                             marginTop + maximumHeight + marginBottom * 0.15f + yOffset,
                                             textSize.width,
                                             textSize.height);
                
                // Only draw if we won't collide with previously drawn text
                if (!CGRectIntersectsRect(textRect, previousRect) && CGRectContainsRect(imageRect, textRect)) {
                    [text drawInRect:textRect withFont:textFont];
                    previousRect = textRect;
                    
                    CGPoint point = CGPointMake(xOffset + pointSpacing * idx, marginTop + maximumHeight);
                    
                    CGContextBeginPath(context);
                    CGContextMoveToPoint(context, point.x, point.y);
                    CGContextAddLineToPoint(context, point.x, point.y + marginBottom * 0.15f);
                    
                    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
                    CGContextSetLineWidth(context, 5.0f);
                    
                    CGContextStrokePath(context);
                    
                    shiftDown = !shiftDown;
                }
            }];
        }
        
        CGContextFlush(context);
        
        UIGraphicsPopContext();
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

+ (UIImage*) createGraph_StackedBarGraph:(NSDictionary*) labels
                                  values:(NSArray*) values
                              attributes:(NSDictionary*) attributes {
    if ([values count] == 0) {
        return nil;
    }
    
    CGFloat width        = attributes[kICLWidthKey]     ? [attributes[kICLWidthKey] floatValue]     : 320.0f;
    CGFloat height       = attributes[kICLHeightKey]    ? [attributes[kICLHeightKey] floatValue]    : 320.0f;
    CGFloat marginLeft   = attributes[kICLMarginLeft]   ? [attributes[kICLMarginLeft] floatValue]   : width * 0.15f;
    CGFloat marginRight  = attributes[kICLMarginRight]  ? [attributes[kICLMarginRight] floatValue]  : width * 0.10f;
    CGFloat marginTop    = attributes[kICLMarginTop]    ? [attributes[kICLMarginTop] floatValue]    : height * 0.1f;
    CGFloat marginBottom = attributes[kICLMarginBottom] ? [attributes[kICLMarginBottom] floatValue] : height * 0.1f;
    CGFloat axisWidth    = attributes[kICLAxisWidth]    ? [attributes[kICLAxisWidth] floatValue]    : 2.0f;
    CGFloat legendHeight = attributes[kICLLegendHeight] ? [attributes[kICLLegendHeight] floatValue] : height * 0.15f;
    
    NSArray* categoryOrders = attributes[kICLCategoryOrders];
    NSDictionary* categoryColours = attributes[kICLCategoryColours];
    
    CGFloat maximumHeight = height - (marginTop + marginBottom + legendHeight);
    CGFloat maximumWidth = width - (marginLeft + marginRight);
    CGFloat barWidth = maximumWidth / [values count];
    
    CGRect imageRect = CGRectMake(0, 0, width, height);
    
    // calculate the sum of all the data values
    __block double highestValue = 0;
    
    if (attributes[kICLMaximumValue]) {
        highestValue = [attributes[kICLMaximumValue] doubleValue];
    }
    else {
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            highestValue = MAX(highestValue, [obj doubleValue]);
        }];
    }
    
    // Determine the scale factor for normalising the data
    double scaleFactor = highestValue == 0 ? 0 : maximumHeight / highestValue;
    
    UIImage* image = nil;
    
    @autoreleasepool {
        // setup the context so we can modify the image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGContextBeginPath(context);
        
        CGFloat barPadding = barWidth * 0.05f;
        __block CGFloat xOffset = marginLeft;
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary* valueSet = (NSDictionary*) obj;
            
            // iterate over all of the categories
            CGFloat yOffset = marginTop + maximumHeight;
            for (NSString* category in categoryOrders) {
                NSNumber* categoryValue = valueSet[category];
                double value = [categoryValue doubleValue];
                
                // skip empty or invalid values
                if (!categoryValue || (value <= 0)) {
                    continue;
                }
                
                // Determine the height of this block and it's colour;
                CGFloat barHeight = value * scaleFactor;
                UIColor* barColour = categoryColours[category];
                
                // Construct the rect for the bar
                CGRect barRect = CGRectMake(xOffset + barPadding,
                                            yOffset - barHeight,
                                            barWidth - (2*barPadding),
                                            barHeight);
                
                // Draw the rectangle
                CGContextSetFillColorWithColor(context, barColour.CGColor);
                CGContextFillRect(context, barRect);
                
                // Update the y offset
                yOffset -= barHeight;
            }
            
            xOffset += barWidth;
        }];
        
        // Draw the axes
        CGContextSetLineWidth(context, axisWidth);
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        
        CGContextMoveToPoint(context, marginLeft, marginTop);
        CGContextAddLineToPoint(context, marginLeft, marginTop + maximumHeight);
        CGContextAddLineToPoint(context, marginLeft + maximumWidth, marginTop + maximumHeight);
        CGContextStrokePath(context);
        
        // Draw the y axis labels if present
        NSArray* yAxisLabels = labels[kICLYAxisLabels];
        if ([yAxisLabels count] > 0) {
            CGFloat fontSize = attributes[kICLFontSize] ? [attributes[kICLFontSize] floatValue] : 12.0f;
            UIFont* textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:fontSize];
            
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            // Draw the labels
            CGFloat heightIncrement = maximumHeight / ([yAxisLabels count] - 1);
            [yAxisLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CGPoint point = CGPointMake(marginLeft, marginTop + maximumHeight - (heightIncrement * idx));
                
                if (point.y < (marginTop - 0.5f)) {
                    *stop = YES;
                }
                else {
                    NSString* text = (NSString*) obj;
                    
                    CGSize textSize = [text sizeWithFont:textFont];
                    
                    CGRect textRect = CGRectMake(marginLeft - textSize.width - marginLeft * 0.075f,
                                                 marginTop + maximumHeight - (heightIncrement * idx) - (textSize.height * 0.5f),
                                                 textSize.width,
                                                 textSize.height);
                    
                    [text drawInRect:textRect withFont:textFont];
                    
                    CGContextBeginPath(context);
                    CGContextMoveToPoint(context, point.x, point.y);
                    CGContextAddLineToPoint(context, point.x - marginLeft * 0.05f, point.y);
                    
                    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
                    CGContextSetLineWidth(context, 5.0f);
                    
                    CGContextStrokePath(context);
                }
            }];
        }
        
        // Draw the x axis labels if present
        NSArray* xAxisLabels = labels[kICLXAxisLabels];
        if ([xAxisLabels count] > 0) {
            CGFloat fontSize = attributes[kICLFontSize] ? [attributes[kICLFontSize] floatValue] : 12.0f;
            UIFont* textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:fontSize];
            
            CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
            
            // Draw the labels
            __block BOOL shiftDown = NO;
            __block CGRect previousRect = CGRectZero;
            __block CGFloat xOffset = marginLeft + barWidth * 0.5f;
            [xAxisLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString* text = (NSString*) obj;
                
                CGSize textSize = [text sizeWithFont:textFont];
                
                CGFloat yOffset = shiftDown ? marginBottom * 0.15f : 0;
                
                CGRect textRect = CGRectMake(xOffset + (barWidth * idx) - (textSize.width * 0.5f),
                                             marginTop + maximumHeight + marginBottom * 0.15f + yOffset,
                                             textSize.width,
                                             textSize.height);
                
                // Only draw if we won't collide with previously drawn text
                if (!CGRectIntersectsRect(textRect, previousRect) && CGRectContainsRect(imageRect, textRect)) {
                    [text drawInRect:textRect withFont:textFont];
                    previousRect = textRect;
                    
                    CGPoint point = CGPointMake(xOffset + barWidth * idx, marginTop + maximumHeight);
                    
                    CGContextBeginPath(context);
                    CGContextMoveToPoint(context, point.x, point.y);
                    CGContextAddLineToPoint(context, point.x, point.y + marginBottom * 0.15f);
                    
                    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
                    CGContextSetLineWidth(context, 5.0f);
                    
                    CGContextStrokePath(context);
                    
                    shiftDown = !shiftDown;
                }
            }];
        }
        
        CGContextFlush(context);
        
        __block CGFloat widestText = 0;
        __block CGFloat highestText = 0;
        
        CGFloat legendFontSize = attributes[kICLFontSize_LegendLabel] ? [attributes[kICLFontSize_LegendLabel] floatValue] : 12.0f;
        UIFont* legendLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:legendFontSize];
        
        // Determine the widest and tallest label data
        [categoryOrders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* labelString = obj;
            CGSize labelStringSize = [labelString sizeWithFont:legendLabelFont];
            
            widestText = MAX(widestText, labelStringSize.width);
            highestText = MAX(highestText, labelStringSize.height);
        }];
        
        // Determine the basic label data
        CGFloat horizontalMargin = widestText * 0.1f;
        CGFloat verticalMargin = highestText * 0.1f;
        
        CGFloat labelWidth = widestText + horizontalMargin;
        CGFloat labelHeight = highestText + verticalMargin;
        
        __block NSUInteger numLabelsPerRow = attributes[kICLNumLabelsAcrossForLegend] ? [attributes[kICLNumLabelsAcrossForLegend] integerValue] : 4;
        NSUInteger numLabels = [categoryOrders count];
        NSUInteger numRows = MAX(1, (numLabels + (numLabelsPerRow - (numLabels % numLabelsPerRow))) / numLabelsPerRow);
        
        CGFloat heightRequired = numRows * (labelHeight + verticalMargin);
        
        CGFloat mostLabelsAcross = numLabels >= numLabelsPerRow ? numLabelsPerRow : (numLabels % numLabelsPerRow);
        CGFloat usedWidth = mostLabelsAcross * (labelWidth + horizontalMargin) - horizontalMargin;
        
        CGSize originalLabelSize = CGSizeMake(MAX(usedWidth + marginLeft + marginRight, width), heightRequired);
        
        // Create a fresh context for the labels
        UIGraphicsBeginImageContextWithOptions(originalLabelSize, NO, 1.0);
        CGContextRef labelContext = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(labelContext);
        
        // Draw the labels
        
        __block CGFloat blockOriginX = originalLabelSize.width < usedWidth ? marginLeft : ((originalLabelSize.width - usedWidth) / 2);
        __block CGFloat blockOriginY = 0;
        
        __block CGFloat workingX = blockOriginX;
        __block CGFloat workingY = blockOriginY;
        
        [categoryOrders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* category = (NSString*) obj;
            UIColor* colour = categoryColours[category];
            
            CGRect labelRect = CGRectMake(workingX, workingY, labelWidth, labelHeight);
            
            // Draw the block for the label
            CGContextSaveGState(labelContext);
            CGContextSetFillColorWithColor(labelContext, colour.CGColor);
            CGContextFillRect(labelContext, labelRect);
            CGContextFlush(labelContext);
            CGContextRestoreGState(labelContext);

            // Determine the size of the label
            CGSize textSize = [category sizeWithFont:legendLabelFont];
            
            // Work out the final text rect
            CGRect textRect = CGRectMake(workingX + (labelWidth - textSize.width) / 2,
                                         workingY + (labelHeight - textSize.height) / 2,
                                         textSize.width,
                                         textSize.height);
            
            // auto select the colour based on the perceived brightness
            CGColorRef cgColour;
            if ([colour perceivedBrightness] < 0.5f) {
                cgColour = [UIColor whiteColor].CGColor;
            }
            else {
                cgColour = [UIColor blackColor].CGColor;
            }
            
            CGContextSaveGState(labelContext);
            CGContextSetFillColorWithColor(labelContext, cgColour);
            
            [category drawInRect:textRect
                           withFont:legendLabelFont
                      lineBreakMode:NSLineBreakByClipping
                          alignment:NSTextAlignmentCenter];
            
            CGContextRestoreGState(labelContext);
            
            if ((idx + 1) % numLabelsPerRow == 0) {
                workingX = blockOriginX;
                workingY += verticalMargin + labelHeight;
            }
            else {
                workingX += horizontalMargin + labelWidth;
            }
        }];
        
        {
            // Flush the context and retrieve the label
            CGContextFlush(labelContext);
            UIGraphicsPopContext();
            UIImage* labelImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // Flush the context and retrieve the graph
            CGContextFlush(context);
            UIGraphicsPopContext();
            UIImage* graphImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // Setup a new context for the combined image
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            UIGraphicsPushContext(context);
            
            CGSize newLabelSize = originalLabelSize;
            
            // label is too wide so rescale
            if (originalLabelSize.width > width) {
                newLabelSize = CGSizeMake(width, (originalLabelSize.height / originalLabelSize.width) * width);
            }
            
            CGRect graphRect = CGRectMake(0, 0, width, height);
            CGRect labelRect;
            
            // If the graph is wider than it is tall then we may need to shrink it
            if (width > height) {
                // If the label block is taking up less than 25% of the height then preserve it's height
                if (newLabelSize.height < legendHeight) {
                    labelRect = CGRectMake(0, height - legendHeight, width, newLabelSize.height);
                }
                else {
                    CGFloat newWidth = (width / newLabelSize.height) * legendHeight;
                    labelRect = CGRectMake((width - newWidth) / 2,
                                           height - legendHeight,
                                           newWidth,
                                           legendHeight);
                }
            } // If the graph is taller than it is high we may have enough room without shrinking it too much
            else {
                // Is the required label height less than our spare height?
                if (newLabelSize.height < legendHeight) {
                    labelRect = CGRectMake(0, height - legendHeight, width, newLabelSize.height);
                } // Otherwise we don't have enough space and need to shrink the graph and label
                else {
                    CGFloat newHeight = MIN(legendHeight, newLabelSize.height);
                    CGFloat newWidth = (width / newLabelSize.height) * newHeight;
                    labelRect = CGRectMake((width - newWidth) / 2,
                                           height - legendHeight,
                                           newWidth,
                                           newHeight);
                }
            }
            
            // Redraw the label and graph chart
            [graphImage drawInRect:graphRect blendMode:kCGBlendModeCopy alpha:1.0];
            [labelImage drawInRect:labelRect blendMode:kCGBlendModeCopy alpha:1.0];
        }
        
        UIGraphicsPopContext();
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

@end
