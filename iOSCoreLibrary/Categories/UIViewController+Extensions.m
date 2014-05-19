//
//  UIViewController+Extensions.m
//  iOSCoreLibrary
//
// This code is from an answer Stack Overflow to this question
// http://stackoverflow.com/questions/6131205/iphone-how-to-find-topmost-view-controller

#import "UIViewController+Extensions.h"

@implementation UIViewController (Extensions)

// This code is from an answer Stack Overflow to this question
// http://stackoverflow.com/questions/6131205/iphone-how-to-find-topmost-view-controller

- (UIViewController*) topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*) topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
