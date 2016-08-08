//
//  HXHSlideAnimatedTransitioning.m
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import "HXHSlideAnimatedTransitioning.h"

static const NSTimeInterval kSlideAnimatedTransitioningDuration = 0.35f;

@implementation HXHSlideAnimatedTransitioning

+ (instancetype)transitioningWithReverse:(BOOL)reverse
{
    return [[self alloc] initWithReverse:reverse];
}

#pragma mark - Initialization
- (instancetype)initWithReverse:(BOOL)reverse
{
    self = [super init];
    if ( self ) {
        self.reverse = reverse;
        self.transitioningInitailOriginX = - [UIScreen mainScreen].bounds.size.width;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning - Delegate

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return kSlideAnimatedTransitioningDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController * fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController * toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView * containerView = [transitionContext containerView];
    UIView * fromView = fromViewController.view;
    UIView * toView = toViewController.view;
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    CGFloat viewWidth = CGRectGetWidth(containerView.frame);
    __block CGRect fromViewFrame = fromView.frame;
    __block CGRect toViewFrame = toView.frame;
    
    toViewFrame.origin.x = self.reverse ? self.transitioningInitailOriginX : viewWidth;
    toView.frame = toViewFrame;
    [containerView addSubview:toView];
    
    if (self.isReverse) {
        [containerView bringSubviewToFront:fromView];
    }
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        toViewFrame.origin.x = CGRectGetMinX(containerView.frame);
        fromViewFrame.origin.x = self.isReverse ? viewWidth : self.transitioningInitailOriginX;
        
        toView.frame = toViewFrame;
        fromView.frame = fromViewFrame;
        
    } completion:^(BOOL finished) {
        
        if (self.isReverse && ![transitionContext transitionWasCancelled]) {
            [fromView removeFromSuperview];
        }
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
