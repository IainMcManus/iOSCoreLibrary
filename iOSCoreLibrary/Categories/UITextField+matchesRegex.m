//
//  UITextField+matchesRegex.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 6/02/13.
//
//

#import "UITextField+matchesRegex.h"

@implementation UITextField (matchesRegex)

- (BOOL) matchesRegex:(NSString *)inRegex {
    if ((!self.text || ([self.text length] == 0)) && ([inRegex length] > 0)) {
        return NO;
    }
    
    if ([inRegex length] == 0) {
        return YES;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:inRegex options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSTextCheckingResult *match = self.text ? [regex firstMatchInString:self.text options:0 range:NSMakeRange(0, [self.text length])] : nil;
    
    return match != nil;
}

@end
