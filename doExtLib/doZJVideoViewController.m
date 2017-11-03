//
//  doZJVideoViewController.m
//
//  Created by zmj on 17/6/7.
//  Copyright © 2017年 zmj. All rights reserved.
//


#import "doZJVideoViewController.h"
#import "doZJVideoView.h"

#define ZJScreenBounds ([[UIScreen mainScreen] bounds])
#define ZJScreenWidth (ZJScreenBounds.size.width)
#define ZJScreenHeight (ZJScreenBounds.size.height)

@interface doZJVideoViewController ()<doZJVideoViewDelegate>
@property (nonatomic, strong) doZJVideoView *videoView;
@property (nonatomic, assign) BOOL isHiddenStatusBar;

@end

@implementation doZJVideoViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSNumber *vcBasseStatuesAppearace = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (!vcBasseStatuesAppearace.boolValue) { // 当前page已无效
        [self applyStatusBarStyleWhenStatusBarAppearanceSettingIsNO];
    }
    

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.videoUrl == nil){
        ZJLog(@"videoUrl 参数未传递");
        return;
    }
    ZJLog(@"宽: %f  高: %f", ZJScreenWidth,ZJScreenHeight);
    self.videoView = [[doZJVideoView alloc] initWithFrame:CGRectMake(0, 0, ZJScreenWidth, ZJScreenHeight) url:self.videoUrl startPlayPoint:self.startPlayPoint];
    self.videoView.delegate = self;
    [self.view addSubview:self.videoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)applyStatusBarStyleWhenStatusBarAppearanceSettingIsNO {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

/// 设置前景色
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

//设置是否隐藏
- (BOOL)prefersStatusBarHidden {
    return self.isHiddenStatusBar;
}

//设置隐藏动画
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

// 只支持横屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

//是否支持自动转屏
- (BOOL)shouldAutorotate{
    return NO;
}
#pragma mark -- doZJVideoViewDelegate

- (void)doZJVideoViewClose:(doZJVideoView *)videoView {
    [self.videoView removeFromSuperview];
    self.videoView = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.navigationController popViewControllerAnimated:false];

}

- (void)doZJVideoViewShowBar:(doZJVideoView *)videoView withIsShow:(BOOL)isShow {
    self.isHiddenStatusBar = !isShow;
    //刷新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
}


@end
