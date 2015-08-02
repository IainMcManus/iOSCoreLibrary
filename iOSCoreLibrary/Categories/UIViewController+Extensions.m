//
//  UIViewController+Extensions.m
//  iOSCoreLibrary
//
// This code is from an answer Stack Overflow to this question
// http://stackoverflow.com/questions/11637709/get-the-current-displaying-uiviewcontroller-on-the-screen-in-appdelegate-m

#import "UIViewController+Extensions.h"

#if TARGET_OS_IPHONE

@implementation UIViewController (Extensions)

// This code is from an answer Stack Overflow to this question
// http://stackoverflow.com/questions/11637709/get-the-current-displaying-uiviewcontroller-on-the-screen-in-appdelegate-m

- (UIViewController*) topViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    // If the main window is not the default (eg. an alert etc) then search for the first normal window
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray* windows = [[UIApplication sharedApplication] windows];
        
        // Find the first normal window
        for (window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews]) {
        UIResponder *responder = [subView nextResponder];
        
        // added this block of code for iOS 8 which puts a UITransitionView in between the UIWindow and the UILayoutContainerView
        if ([responder isEqual:window]) {
            // this is a UITransitionView
            if ([[subView subviews] count]) {
                UIView *subSubView = [subView subviews][0]; // this should be the UILayoutContainerView
                responder = [subSubView nextResponder];
            }
        }
        
        if ([responder isKindOfClass:[UIViewController class]]) {
            return [UIViewController topViewControllerWithRootViewController:(UIViewController*) responder];
        }
    }
    
    return nil;
}

+ (UIViewController*) topViewControllerWithRootViewController:(UIViewController*) controller {
    BOOL isPresenting = NO;
    
    do {
        // this path is called only on iOS 6+, so -presentedViewController is fine here.
        UIViewController *presented = [controller presentedViewController];
        isPresenting = presented != nil;
        
        if (presented != nil) {
            controller = presented;
        }
        
    } while (isPresenting);
    
    return controller;
}

@end

#endif // TARGET_OS_IPHONE