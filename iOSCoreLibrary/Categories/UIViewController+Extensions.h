//
//  UIViewController+Extensions.h
//  iOSCoreLibrary
//
// This code is from an answer Stack Overflow to this question
// http://stackoverflow.com/questions/11637709/get-the-current-displaying-uiviewcontroller-on-the-screen-in-appdelegate-m

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface UIViewController (Extensions)

- (UIViewController*) topViewController;
+ (UIViewController*) topViewControllerWithRootViewController:(UIViewController*)rootViewController;

@end


#endif // TARGET_OS_IPHONE