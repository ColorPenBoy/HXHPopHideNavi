//
//  HXHSlideAnimatedTransitioning.h
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HXHSlideAnimatedTransitioning : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isReverse) BOOL reverse;
@property (nonatomic, assign) CGFloat transitioningInitailOriginX;

- (instancetype)initWithReverse:(BOOL)reverse;
+ (instancetype)transitioningWithReverse:(BOOL)reverse;

@end
