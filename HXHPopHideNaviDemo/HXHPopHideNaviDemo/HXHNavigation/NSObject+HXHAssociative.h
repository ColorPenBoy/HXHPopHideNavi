//
//  NSObject+HXHAssociative.h
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (HXHAssociative)

/**
 *  Runtime - 关联属性
 */
- (id)hxh_associativeObjectForKey:(NSString *)key;
- (void)hxh_removeAssociatedObjectForKey:(NSString *)key;
- (void)hxh_setAssociativeObject:(id)object forKey:(NSString *)key;

@end
