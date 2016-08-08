//
//  UIView+HXHSnipScreen.m
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import "UIView+HXHSnipScreen.h"

@implementation UIView (HXHSnipScreen)

- (UIImage *)hxh_getSnipScreenImage {
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
        
    } else {
        
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
