//
//  UIViewController+Extensions.h
//  iOSCoreLibrary
//
// This code is from an answer Stack Overflow to this question
// http://stackoverflow.com/questions/6131205/iphone-how-to-find-topmost-view-controller

#import <UIKit/UIKit.h>

@interface UIViewController (Extensions)

- (UIViewController*) topViewController;
- (UIViewController*) topViewControllerWithRootViewController:(UIViewController*)rootViewController;

@end
