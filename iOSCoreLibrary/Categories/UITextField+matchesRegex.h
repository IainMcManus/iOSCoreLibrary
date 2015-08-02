//
//  UITextField+matchesRegex.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 6/02/13.
//
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface UITextField (matchesRegex)

- (BOOL) matchesRegex:(NSString*) inRegex;

@end

#endif // TARGET_OS_IPHONE