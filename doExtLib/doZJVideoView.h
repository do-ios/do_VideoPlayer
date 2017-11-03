//
//  doZJVideoView.h
//
//  Created by zmj on 17/6/7.
//  Copyright © 2017年 zmj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#ifdef DEBUG
#ifndef ZJLog
#define ZJLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif
#else
#ifndef ZJLog
#define ZJLog(...)
#endif
#endif

//Block回调方法
typedef void(^FullScreenBlock)(BOOL isFull);

typedef void(^ClosePLayerBlock)();

typedef void(^ShowBarBlock)(BOOL isShow);

typedef void(^PlayFinishedBlock)();


@class doZJVideoView;
/// 代理方法
@protocol doZJVideoViewDelegate<NSObject>

/// 播放结束
- (void)doZJVideoViewPlayFinished:(doZJVideoView *)videoView;

/// 关闭播放器
- (void)doZJVideoViewClose:(doZJVideoView *)videoView;

/// 全屏按钮
- (void)doZJVideoViewFullScreen:(doZJVideoView *)videoView withIsFull:(BOOL)isFull;

/// 隐藏/展示footBar和topBar
- (void)doZJVideoViewShowBar:(doZJVideoView *)videoView withIsShow:(BOOL)isShow;

@end

@interface doZJVideoView : UIView


/// 全屏/退出全屏的回调
@property (nonatomic, copy) FullScreenBlock  fullScreenBlock;

/// 关闭按钮的回调
@property (nonatomic, copy) ClosePLayerBlock closePLayerBlock;

/// 隐藏footBar和topBar回调
@property (nonatomic, copy) ShowBarBlock showBarBlock;

/// 播放完成的回调
@property (nonatomic, copy) PlayFinishedBlock playFinishedBlock;

/// 代理
@property (nonatomic, assign) id <doZJVideoViewDelegate>delegate;

/// 是否是直接全屏播放
@property (nonatomic, assign) BOOL straightFull;

/// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url startPlayPoint:(NSInteger)startPlayPoint;


@end
