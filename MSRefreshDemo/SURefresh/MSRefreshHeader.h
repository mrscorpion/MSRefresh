//
//  MSRefreshHeader.h
//  CircleProgressView
//
//  Created by mr.scorpion on 16/7/5.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+MSRefresh.h"

@interface MSRefreshHeader : UIView

UIKIT_EXTERN const CGFloat MSRefreshHeaderHeight;
UIKIT_EXTERN const CGFloat MSRefreshPointRadius;

@property (nonatomic, copy) void(^handle)();

#pragma mark - 停止动画
- (void)endRefreshing;
@end
