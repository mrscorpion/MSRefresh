//
//  MSRefreshHeader.m
//  CircleProgressView
//
//  Created by mr.scorpion on 16/7/5.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import "MSRefreshHeader.h"
#import "UIView+MSRefresh.h"

const CGFloat MSRefreshHeaderHeight = 35.0;
const CGFloat MSRefreshPointRadius = 5.0;

const CGFloat MSRefreshPullLen     = 55.0;
const CGFloat MSRefreshTranslatLen = 5.0;

#define topPointColor    [UIColor colorWithRed:90 / 255.0 green:200 / 255.0 blue:200 / 255.0 alpha:1.0].CGColor
#define leftPointColor   [UIColor colorWithRed:250 / 255.0 green:85 / 255.0 blue:78 / 255.0 alpha:1.0].CGColor
#define bottomPointColor [UIColor colorWithRed:92 / 255.0 green:201 / 255.0 blue:105 / 255.0 alpha:1.0].CGColor
#define rightPointColor  [UIColor colorWithRed:253 / 255.0 green:175 / 255.0 blue:75 / 255.0 alpha:1.0].CGColor

@interface MSRefreshHeader ()

@property (nonatomic, weak  ) UIScrollView * scrollView;
@property (nonatomic, strong) CAShapeLayer * lineLayer;
@property (nonatomic, strong) CAShapeLayer * TopPointLayer;
@property (nonatomic, strong) CAShapeLayer * BottomPointLayer;
@property (nonatomic, strong) CAShapeLayer * LeftPointLayer;
@property (nonatomic, strong) CAShapeLayer * rightPointLayer;

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL animating;
@end

@implementation MSRefreshHeader
- (instancetype)init
{
    if (self = [super initWithFrame:CGRectMake(0, 0, MSRefreshHeaderHeight, MSRefreshHeaderHeight)]) {
        [self initLayers];
    }
    return self;
}


#pragma mark - Iniatial
- (void)initLayers {
    CGFloat centerLine = MSRefreshHeaderHeight / 2;
    CGFloat radius = MSRefreshPointRadius;
    //
    CGPoint topPoint = CGPointMake(centerLine, radius);
    self.TopPointLayer = [self layerWithPoint:topPoint color:topPointColor];
    self.TopPointLayer.hidden = NO;
    self.TopPointLayer.opacity = 0.f;
    [self.layer addSublayer:self.TopPointLayer];
    
    CGPoint leftPoint = CGPointMake(radius, centerLine);
    self.LeftPointLayer = [self layerWithPoint:leftPoint color:leftPointColor];
    [self.layer addSublayer:self.LeftPointLayer];
    
    CGPoint bottomPoint = CGPointMake(centerLine, MSRefreshHeaderHeight - radius);
    self.BottomPointLayer = [self layerWithPoint:bottomPoint color:bottomPointColor];
    [self.layer addSublayer:self.BottomPointLayer];
    
    CGPoint rightPoint = CGPointMake(MSRefreshHeaderHeight - radius, centerLine);
    self.rightPointLayer = [self layerWithPoint:rightPoint color:rightPointColor];
    [self.layer addSublayer:self.rightPointLayer];
    
    //
    self.lineLayer = [CAShapeLayer layer];
    self.lineLayer.frame = self.bounds;
    self.lineLayer.lineWidth = MSRefreshPointRadius * 2;
    self.lineLayer.lineCap = kCALineCapRound;
    self.lineLayer.lineJoin = kCALineJoinRound;
    self.lineLayer.fillColor = topPointColor;
    self.lineLayer.strokeColor = topPointColor;
    UIBezierPath * path = [UIBezierPath bezierPath];
    [path moveToPoint:topPoint];
    [path addLineToPoint:leftPoint];
    [path moveToPoint:leftPoint];
    [path addLineToPoint:bottomPoint];
    [path moveToPoint:bottomPoint];
    [path addLineToPoint:rightPoint];
    [path moveToPoint:rightPoint];
    [path addLineToPoint:topPoint];
    self.lineLayer.path = path.CGPath;
    self.lineLayer.strokeStart = 0.f;
    self.lineLayer.strokeEnd = 0.f;
    [self.layer insertSublayer:self.lineLayer above:self.TopPointLayer];
}

- (CAShapeLayer *)layerWithPoint:(CGPoint)center color:(CGColorRef)color {
    CAShapeLayer * layer = [CAShapeLayer layer];
    layer.frame = CGRectMake(center.x - MSRefreshPointRadius, center.y - MSRefreshPointRadius, MSRefreshPointRadius * 2, MSRefreshPointRadius * 2);
    layer.fillColor = color;
    layer.path = [self pointPath];
    layer.hidden = YES;
    return layer;
}

- (CGPathRef)pointPath {
    return [UIBezierPath bezierPathWithArcCenter:CGPointMake(MSRefreshPointRadius, MSRefreshPointRadius) radius:MSRefreshPointRadius startAngle:0 endAngle:M_PI * 2 clockwise:YES].CGPath;
}

#pragma mark - Override
- (void)willMoveToSuperview:(UIView *)newMSperview {
    [super willMoveToSuperview:newMSperview];
    if (newMSperview) {
        self.scrollView = (UIScrollView *)newMSperview;
        self.center = CGPointMake(self.scrollView.centerX, self.centerY);
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }else {
        [self.superview removeObserver:self forKeyPath:@"contentOffset"];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        self.progress = - self.scrollView.contentOffset.y;
    }
}

#pragma mark - Property
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    //如果不是正在刷新，则渐变动画
    if (!self.animating) {
        if (progress >= MSRefreshPullLen) {
            self.y = - (MSRefreshPullLen - (MSRefreshPullLen - MSRefreshHeaderHeight) / 2);
        }else {
            if (progress <= self.h) {
                self.y = - progress;
            }else {
                self.y = - (self.h + (progress - self.h) / 2);
            }
        }
        [self setLineLayerStrokeWithProgress:progress];
    }
    //如果到达临界点，则执行刷新动画
    if (progress >= MSRefreshPullLen && !self.animating && !self.scrollView.dragging) {
        [self startAni];
        if (self.handle) {
            self.handle();
        }
    }
}

#pragma mark - Adjustment
- (void)setLineLayerStrokeWithProgress:(CGFloat)progress {
    float startProgress = 0.f;
    float endProgress = 0.f;
    
    //隐藏
    if (progress < 0) {
        self.TopPointLayer.opacity = 0.f;
        [self adjustPointStateWithIndex:0];
    }
    else if (progress >= 0 && progress < (MSRefreshPullLen - 40)) {
        self.TopPointLayer.opacity = progress / 20;
        [self adjustPointStateWithIndex:0];
    }
    else if (progress >= (MSRefreshPullLen - 40) && progress < MSRefreshPullLen) {
        self.TopPointLayer.opacity = 1.0;
        //大阶段 0 ~ 3
        NSInteger stage = (progress - (MSRefreshPullLen - 40)) / 10;
        //大阶段的前半段
        CGFloat MSbProgress = (progress - (MSRefreshPullLen - 40)) - (stage * 10);
        if (MSbProgress >= 0 && MSbProgress <= 5) {
            [self adjustPointStateWithIndex:stage * 2];
            startProgress = stage / 4.0;
            endProgress = stage / 4.0 + MSbProgress / 40.0 * 2;
        }
        //大阶段的后半段
        if (MSbProgress > 5 && MSbProgress < 10) {
            [self adjustPointStateWithIndex:stage * 2 + 1];
            startProgress = stage / 4.0 + (MSbProgress - 5) / 40.0 * 2;
            if (startProgress < (stage + 1) / 4.0 - 0.1) {
                startProgress = (stage + 1) / 4.0 - 0.1;
            }
            endProgress = (stage + 1) / 4.0;
        }
    }
    else {
        self.TopPointLayer.opacity = 1.0;
        [self adjustPointStateWithIndex:NSIntegerMax];
        startProgress = 1.0;
        endProgress = 1.0;
    }
    self.lineLayer.strokeStart = startProgress;
    self.lineLayer.strokeEnd = endProgress;
}

- (void)adjustPointStateWithIndex:(NSInteger)index { //index : 小阶段： 0 ~ 7
    self.LeftPointLayer.hidden = index > 1 ? NO : YES;
    self.BottomPointLayer.hidden = index > 3 ? NO : YES;
    self.rightPointLayer.hidden = index > 5 ? NO : YES;
    self.lineLayer.strokeColor = index > 5 ? rightPointColor : index > 3 ? bottomPointColor : index > 1 ? leftPointColor : topPointColor;
}

#pragma mark - Animation
- (void)startAni {
    self.animating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        UIEdgeInsets inset = self.scrollView.contentInset;
        inset.top = MSRefreshPullLen;
        self.scrollView.contentInset = inset;
    }];
    [self addTranslationAniToLayer:self.TopPointLayer xValue:0 yValue:MSRefreshTranslatLen];
    [self addTranslationAniToLayer:self.LeftPointLayer xValue:MSRefreshTranslatLen yValue:0];
    [self addTranslationAniToLayer:self.BottomPointLayer xValue:0 yValue:-MSRefreshTranslatLen];
    [self addTranslationAniToLayer:self.rightPointLayer xValue:-MSRefreshTranslatLen yValue:0];
    [self addRotationAniToLayer:self.layer];
}

- (void)addTranslationAniToLayer:(CALayer *)layer xValue:(CGFloat)x yValue:(CGFloat)y {
    CAKeyframeAnimation * translationKeyframeAni = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    translationKeyframeAni.duration = 1.0;
    translationKeyframeAni.repeatCount = HUGE;
    translationKeyframeAni.removedOnCompletion = NO;
    translationKeyframeAni.fillMode = kCAFillModeForwards;
    translationKeyframeAni.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    NSValue * fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 0, 0.f)];
    NSValue * toValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(x, y, 0.f)];
    translationKeyframeAni.values = @[fromValue, toValue, fromValue, toValue, fromValue];
    [layer addAnimation:translationKeyframeAni forKey:@"translationKeyframeAni"];
}

- (void)addRotationAniToLayer:(CALayer *)layer {
    CABasicAnimation * rotationAni = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAni.fromValue = @(0);
    rotationAni.toValue = @(M_PI * 2);
    rotationAni.duration = 1.0;
    rotationAni.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    rotationAni.repeatCount = HUGE;
    rotationAni.fillMode = kCAFillModeForwards;
    rotationAni.removedOnCompletion = NO;
    [layer addAnimation:rotationAni forKey:@"rotationAni"];
}

- (void)removeAni {
    [UIView animateWithDuration:0.5 animations:^{
        UIEdgeInsets inset = self.scrollView.contentInset;
        inset.top = 0.f;
        self.scrollView.contentInset = inset;
    } completion:^(BOOL finished) {
        [self.TopPointLayer removeAllAnimations];
        [self.LeftPointLayer removeAllAnimations];
        [self.BottomPointLayer removeAllAnimations];
        [self.rightPointLayer removeAllAnimations];
        [self.layer removeAllAnimations];
        [self adjustPointStateWithIndex:0];
        self.animating = NO;
    }];
}

#pragma mark - Stop
- (void)endRefreshing {
    [self removeAni];
}

@end
