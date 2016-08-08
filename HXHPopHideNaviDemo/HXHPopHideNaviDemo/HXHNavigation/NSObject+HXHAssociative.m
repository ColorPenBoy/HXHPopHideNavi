//
//  NSObject+HXHAssociative.m
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import "NSObject+HXHAssociative.h"
#import <objc/runtime.h>

static char associativeObjectsKey;

@implementation NSObject (HXHAssociative)

- (id)hxh_associativeObjectForKey:(NSString *)key
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, &associativeObjectsKey);
    
    return [dict objectForKey:key];
}

- (void)hxh_removeAssociatedObjectForKey:(NSString *)key
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, &associativeObjectsKey);
    
    [dict removeObjectForKey:key];
}

- (void)hxh_setAssociativeObject:(id)object forKey:(NSString *)key {
    
    NSMutableDictionary *dict = objc_getAssociatedObject(self, &associativeObjectsKey);
    
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &associativeObjectsKey, dict, OBJC_ASSOCIATION_RETAIN);
    }
    
    if (object == nil) {
        [dict removeObjectForKey:key];
    } else {
        [dict setObject:object forKey:key];
    }
}

@end
