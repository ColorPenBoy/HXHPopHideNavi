//
//  HXHNavigationController.m
//  HXHPopHideNaviDemo
//
//  Created by 张强 on 16/8/8.
//  Copyright © 2016年 ColorPen. All rights reserved.
//

#import "HXHNavigationController.h"
#import "UIView+HXHSnipScreen.h"
#import "NSObject+HXHAssociative.h"
#import "HXHSlideAnimatedTransitioning.h"

static NSTimeInterval const kCCNavigationControllerSlidingAnimationDuration = 0.35f;
static CGFloat const kCCNavigationControllerPanVelocityPositiveThreshold = 300.0f;
static CGFloat const kCCNavigationControllerPanVelocityNegativeThreshold = - 300.0f;
static CGFloat const kCCNavigationControllerPanProgressThreshold = 0.3f;

static NSURL * _snapshotCacheURL = nil;
static BOOL _cacheSnapshotImageInMemory = YES;

@interface HXHNavigationController () <UINavigationControllerDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *previousSnapshotView;// 截屏
@property (nonatomic, assign) CGPoint gestureBeganPoint;        // 手势起始坐标
@property (nonatomic, assign) float transitioningProgress;      // 记录转场过渡进度（百分比）

@end

@implementation HXHNavigationController

#pragma mark - Life Cycle
- (void)dealloc {
    [self.backgroundView removeFromSuperview];
}

+ (void)initialize
{
    @autoreleasepool {
        // 清除缓存
        [[self class] removeCacheDirectory];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [[self class] setCacheSnapshotImageInMemory:NO];
        
        [[self class] createCacheDirectory];
        
        _previousSlideViewInitailOriginX = - 200;
        _slidingPopEnable = YES;
        _useSystemAnimatedTransitioning = NO;
        _edgePopGestureOnly = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.view.layer.shadowOffset = CGSizeMake(6, 6);
    self.view.layer.shadowRadius = 5;
    self.view.layer.shadowOpacity = 0.9;
    self.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.bounds].CGPath;
    
    if (self.isSlidingPopEnable) { // 如果允许侧滑返回，添加手势
        if ([self isAboveIOS7]) {
            self.interactivePopGestureRecognizer.enabled = NO;
        }
        [self addPanGestureRecognizers];
    }
    
    if (self.isUseSystemAnimatedTransitioning) {
        // 设置delegate
        self.delegate = self;
    }
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{

    if (UINavigationControllerOperationPush == operation) {
        HXHSlideAnimatedTransitioning *transitoning = [[HXHSlideAnimatedTransitioning alloc] initWithReverse:NO];
        transitoning.transitioningInitailOriginX = self.previousSlideViewInitailOriginX;
        return transitoning;
    }
    return nil;
}

#pragma mark - Helper

- (BOOL)isAboveIOS7 {
    // 系统版本高于 iOS 7
    return [[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending;
}

- (NSString *)encodedFilePathForKey:(NSString *)key
{
    if (![key length]){
        return nil;
    }
    
    return [[[[self class] snapshotCacheURL] URLByAppendingPathComponent:[NSString stringWithUTF8String:[key UTF8String]]] path];
}

#pragma mark - Public

+ (BOOL)cacheSnapshotImageInMemory {
    // 缓存中缓存截屏
    return _cacheSnapshotImageInMemory;
}

+ (void)setCacheSnapshotImageInMemory:(BOOL)cacheSnapshotImageInMemory {
    _cacheSnapshotImageInMemory = cacheSnapshotImageInMemory;
}

#pragma mark - Private

+ (NSURL *)snapshotCacheURL {
    
    if (!_snapshotCacheURL) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _snapshotCacheURL = [NSURL fileURLWithPathComponents:@[[paths objectAtIndex:0], @"SnapshotCache"]];
    }
    return _snapshotCacheURL;
}

+ (BOOL)createCacheDirectory {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[[self class]snapshotCacheURL] path]]) {
        return NO;
    }
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:[[self class]snapshotCacheURL]
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:&error];
    return success;
}

+ (BOOL)removeCacheDirectory {
    NSError *error = nil;
    return [[NSFileManager defaultManager] removeItemAtURL:[[self class]snapshotCacheURL] error:&error];
}

// 设置转场动画进度（百分比）-> 范围在0~1之间
- (void)setTransitioningProgress:(float)transitioningProgress {
    _transitioningProgress = MIN(1,MAX(0, transitioningProgress));
}

- (void)layoutViewsWithTransitioningProgress:(float)progress {
    
    self.transitioningProgress = progress;
    
    CGRect frame = self.view.frame;
    frame.origin.x = CGRectGetWidth([[UIScreen mainScreen] bounds]) * self.transitioningProgress;
    self.view.frame = frame;
    
    CGRect previewFrame = self.previousSnapshotView.frame;
    CGFloat offset = frame.origin.x * self.previousSlideViewInitailOriginX / previewFrame.size.width;
    previewFrame.origin.x = self.previousSlideViewInitailOriginX - offset;
    self.previousSnapshotView.frame = previewFrame;
}

// 执行Pop动画
- (void)excutePopAnimationWithDuration:(NSTimeInterval)duration completion:(void (^)(BOOL finish))completion {
    
    [UIView animateWithDuration:duration animations:^{
        
        [self layoutViewsWithTransitioningProgress:1];
        
    } completion:^(BOOL finished) {
        
        self.backgroundView.hidden = YES;
        [self layoutViewsWithTransitioningProgress:0];
        if (completion) {
            completion(finished);
        }
    }];
}

// 屏幕截图
- (void)createPreviousSnapshotView {
    
    if (!self.backgroundView) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
    }
    self.backgroundView.hidden = NO;
    
    [self.previousSnapshotView removeFromSuperview];
    self.previousSnapshotView = [[UIImageView alloc]initWithImage:[self snapshotForViewController:self.topViewController]];
    
    CGRect frame = self.backgroundView.bounds;
    frame.origin.x = self.previousSlideViewInitailOriginX;
    self.previousSnapshotView.frame = frame;
    
    [self.backgroundView addSubview:self.previousSnapshotView];
}

#pragma mark - Overwrite

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    [self saveSnapshotImage:[self.view hxh_getSnipScreenImage] forViewController:viewController];
    
    if (animated && !self.isUseSystemAnimatedTransitioning) {
        [self createPreviousSnapshotView];
        self.previousSnapshotView.image = [self snapshotForViewController:viewController];
        
        [super pushViewController:viewController animated:NO];
        
        [self layoutViewsWithTransitioningProgress:1];
        [UIView animateWithDuration:kCCNavigationControllerSlidingAnimationDuration animations:^{
            [self layoutViewsWithTransitioningProgress:0];
        }];
    } else {
        [super pushViewController:viewController animated:animated];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    
    UIViewController *popedViewController = nil;
    if (animated && !self.isUseSystemAnimatedTransitioning && self.viewControllers.count > 1) {
        [self createPreviousSnapshotView];
        
        [self removeSnapshotForViewController:self.topViewController];
        popedViewController = self.topViewController;
        
        [self layoutViewsWithTransitioningProgress:0];
        [self excutePopAnimationWithDuration:kCCNavigationControllerSlidingAnimationDuration completion:^(BOOL finish) {
            [super popViewControllerAnimated:NO];
        }];
    } else {
        [self removeSnapshotForViewController:self.topViewController];
        popedViewController = [super popViewControllerAnimated:animated];
    }
    
    return popedViewController;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    
    NSArray *popedControllers = nil;
    if (animated && !self.isUseSystemAnimatedTransitioning && self.viewControllers.count > 1) {
        [self createPreviousSnapshotView];
        self.previousSnapshotView.image = [self snapshotForViewController:self.viewControllers[1]];
        
        [self layoutViewsWithTransitioningProgress:0];
        
        NSMutableArray *mutablePopedControllers = [self.viewControllers mutableCopy];
        [mutablePopedControllers removeObjectAtIndex:0];
        popedControllers = mutablePopedControllers;
        
        [self excutePopAnimationWithDuration:kCCNavigationControllerSlidingAnimationDuration completion:^(BOOL finish) {
            [super popToRootViewControllerAnimated:NO];
        }];
    } else {
        popedControllers = [super popToRootViewControllerAnimated:animated];
    }
    
    for (UIViewController *controller in popedControllers) {
        [self removeSnapshotForViewController:controller];
    }
    return popedControllers;
}

#pragma mark - Snapshot

- (void)saveSnapshotImage:(UIImage *)snapshotImage forViewController:(UIViewController *)controller
{
    [controller hxh_setAssociativeObject:snapshotImage forKey:[self cacheSnapshotImageKeyForViewController:controller]];
    
    if (![[self class] cacheSnapshotImageInMemory]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *path = [self encodedFilePathForKey:[self cacheSnapshotImageKeyForViewController:controller]];
            BOOL isArchiveSuccess = [NSKeyedArchiver archiveRootObject:snapshotImage toFile:path];
            if (isArchiveSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [controller hxh_setAssociativeObject:nil forKey:[self cacheSnapshotImageKeyForViewController:controller]];
                });
            }
        });
    }
}

- (UIImage *)snapshotForViewController:(UIViewController *)controller
{
    UIImage *image = [controller hxh_associativeObjectForKey:[self cacheSnapshotImageKeyForViewController:controller]];
    if (!image) {
        NSString *path = [self encodedFilePathForKey:[self cacheSnapshotImageKeyForViewController:controller]];
        image = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    return image;
}

- (void)removeSnapshotForViewController:(UIViewController *)controller
{
    [controller hxh_setAssociativeObject:nil forKey:[self cacheSnapshotImageKeyForViewController:controller]];
    NSString *path = [self encodedFilePathForKey:[self cacheSnapshotImageKeyForViewController:controller]];
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    [fileManager removeItemAtPath:path error:nil];
}

- (NSString *)cacheSnapshotImageKeyForViewController:(UIViewController *)controller
{
    return [NSString stringWithFormat:@"%lu_SnapshotImageKey.png", (unsigned long)controller.hash];
}

#pragma mark - 添加手势
- (void)addPanGestureRecognizers
{
    if (self.edgePopGestureOnly && NSClassFromString(@"UIScreenEdgePanGestureRecognizer")) {
        
        // 屏幕边缘侧滑手势
        UIScreenEdgePanGestureRecognizer * edgePan = [[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self
                                                                                                      action:@selector(handlePanGestureRecognizer:)];
        edgePan.edges = UIRectEdgeLeft;
        [self.view addGestureRecognizer:edgePan];
        
    } else {
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
        [self.view addGestureRecognizer:pan];
    }
}

#pragma mark - 侧滑手势 && 非侧滑手势
- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)pan
{
    /**
     *  判断条件：
     *  1、如果Nav中的VC数量小于2个
     *  2、禁止侧滑返回
     *  3、触摸点为2个以上
     */
    if (self.viewControllers.count < 2 || !self.isSlidingPopEnable || [pan numberOfTouches] > 1) {
        return;
    }
    
    // 承载触摸点位置
    CGPoint point = [pan locationInView:[UIApplication sharedApplication].keyWindow];
    self.transitioningProgress = (point.x - self.gestureBeganPoint.x) / [UIScreen mainScreen].bounds.size.width;
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.gestureBeganPoint = point;
            [self createPreviousSnapshotView];
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            [self layoutViewsWithTransitioningProgress:self.transitioningProgress];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            CGPoint velocity = [pan velocityInView:pan.view];
            BOOL isFastPositiveSwipe = velocity.x > kCCNavigationControllerPanVelocityPositiveThreshold;
            BOOL isFastNegativeSwipe = velocity.x < kCCNavigationControllerPanVelocityNegativeThreshold;
            NSTimeInterval duration = kCCNavigationControllerSlidingAnimationDuration * ((isFastNegativeSwipe || isFastPositiveSwipe) ? 0.3 : 1);
            
            if ((self.transitioningProgress > kCCNavigationControllerPanProgressThreshold && !isFastNegativeSwipe) || isFastPositiveSwipe) {
                [self excutePopAnimationWithDuration:duration completion:^(BOOL finish) {
                    [self popViewControllerAnimated:NO];
                }];
            } else {
                [UIView animateWithDuration:duration animations:^{
                    [self layoutViewsWithTransitioningProgress:0];
                }];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
