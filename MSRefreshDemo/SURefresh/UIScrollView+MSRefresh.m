//
//  UIScrollView+MSRefresh.m
//  CircleProgressView
//
//  Created by mr.scorpion on 16/7/5.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import "UIScrollView+MSRefresh.h"
#import <objc/runtime.h>
#import "MSRefreshHeader.h"

@implementation UIScrollView (MSRefresh)

- (void)addRefreshHeaderWithHandle:(void (^)())handle {
    MSRefreshHeader * header = [[MSRefreshHeader alloc]init];
    header.handle = handle;
    self.header = header;
    [self insertSubview:header atIndex:0];
}

#pragma mark - Associate
- (void)setHeader:(MSRefreshHeader *)header {
    objc_setAssociatedObject(self, @selector(header), header, OBJC_ASSOCIATION_ASSIGN);
}

- (MSRefreshHeader *)header {
    return objc_getAssociatedObject(self, @selector(header));
}

#pragma mark - Swizzle
+ (void)load {
    Method originalMethod = class_getInstanceMethod([self class], NSSelectorFromString(@"dealloc"));
    Method swizzleMethod = class_getInstanceMethod([self class], NSSelectorFromString(@"MS_dealloc"));
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (void)MS_dealloc {
    self.header = nil;
    [self MS_dealloc];
}

@end
