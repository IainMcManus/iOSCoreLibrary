//
//  ICLDatePickerTransition.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 17/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "ICLDatePickerTransition.h"

@implementation ICLDatePickerTransition

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.isPresenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect startFrame = CGRectMake(0,
                                       fromViewController.view.frame.size.height,
                                       toViewController.view.frame.size.width,
                                       toViewController.view.frame.size.height);
        
        CGRect endFrame = CGRectMake(0,
                                     fromViewController.view.frame.size.height - toViewController.view.frame.size.height,
                                     toViewController.view.frame.size.width,
                                     toViewController.view.frame.size.height);
        
        if ([fromViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController* tabBarController = (UITabBarController*) fromViewController;
            endFrame.origin = CGPointMake(endFrame.origin.x, endFrame.origin.y - tabBarController.tabBar.frame.size.height);
        }
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
                             toViewController.view.frame = endFrame;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
    else {
        toViewController.view.userInteractionEnabled = YES;
        
        CGRect endFrame = CGRectMake(0,
                                       toViewController.view.frame.size.height,
                                       fromViewController.view.frame.size.width,
                                       fromViewController.view.frame.size.height);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
                             fromViewController.view.frame = endFrame;
                         }
                         completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5f;
}

@end
