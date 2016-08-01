//
//  UIScrollView+MSRefresh.h
//  CircleProgressView
//
//  Created by mr.scorpion on 16/7/5.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MSRefreshHeader;

@interface UIScrollView (MSRefresh)
@property (nonatomic, weak, readonly) MSRefreshHeader * header;

- (void)addRefreshHeaderWithHandle:(void (^)())handle;
@end
