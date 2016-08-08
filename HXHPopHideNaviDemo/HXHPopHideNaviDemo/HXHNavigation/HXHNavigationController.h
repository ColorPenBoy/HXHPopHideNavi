//
//  HXHNavigationController.h
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HXHNavigationController : UINavigationController

@property (nonatomic, assign) CGFloat previousSlideViewInitailOriginX;

// 允许侧滑手势返回 -> Default YES
@property (nonatomic, assign, getter = isSlidingPopEnable) BOOL slidingPopEnable;

// 使用系统默认转场动画 -> Default NO
@property (nonatomic, assign, getter = isUseSystemAnimatedTransitioning) BOOL useSystemAnimatedTransitioning;

// 单一屏幕边缘pop手势
@property (nonatomic, assign) BOOL edgePopGestureOnly;

+ (void)setCacheSnapshotImageInMemory:(BOOL)cacheSnapshotImageInMemory;

@end
