//
//  doZJVideoView.m
//
//  Created by zmj on 17/6/7.
//  Copyright © 2017年 zmj. All rights reserved.
//
#import "doZJVideoView.h"

#define ZJVIDEOVIEWWIDTH (self.frame.size.width)
#define ZJVIDEOVIEWHEIGHT (self.frame.size.height)

#define ZJScreenBounds ([[UIScreen mainScreen] bounds])
#define ZJScreenWidth (ZJScreenBounds.size.width)
#define ZJScreenHeight (ZJScreenBounds.size.height)


#define ZJTopToolBarH 55.0
#define CloseBtnW 35.0
#define CloseBtnH CloseBtnW
#define CloseBtnLeftTopGap 20.0


#define ZJBottomToolBarH 40.0

#define ZJToolBarHorizontalGap 10.0
#define ZJToolBarVerticalGap 5.0

#define PlayBtnW 30.0
#define PlayBtnH 30.0

#define FullScreenBtnW PlayBtnW
#define FullScreenBtnH PlayBtnH

#define TimeLabelW 50.0
#define TimeLabelH PlayBtnH


#define ProgressViewH 1.0

typedef enum{
    ZJVideoScreenRatioCover, // 全屏
    ZJVideoScreenRatioThreeQuarters,    // 75%
    ZJVideoScreenRatioHalf, // 50%
}ZJVideoScreenRatio;



@interface doZJVideoView ()

@property (nonatomic, assign) CGRect initFrame;  // 初始化的frame

@property (nonatomic, assign) BOOL isFullScreen; // 是否全屏
@property (nonatomic, assign) BOOL isShowBar;  // 是否隐藏UI
@property (nonatomic, assign) BOOL dragSlider; // 是否正在拖拽

@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerLayer *videoLayer; // 视频播放layer
@property (nonatomic, strong) id playerTimeObserver; // 播放进度观察者

@property (nonatomic, strong) UIView *topToolBar; // 顶部工具栏
@property (nonatomic, strong) UIButton *closeBtn; // 关闭按钮
/*videoLayer播放比例*/
@property (nonatomic, strong) UIButton *coveredBtn; // 铺满
@property (nonatomic, strong) UIButton *halfBtn; // 0.5
@property (nonatomic, strong) UIButton *threeQuartersBtn; // 0.75

@property (nonatomic, strong) UIView *bottomToolBar; // 底部工具栏
@property (nonatomic, strong) UIButton *playBtn; // 播放按钮
@property (nonatomic, strong) UIButton *fullScreenBtn; // 全屏按钮
@property (nonatomic, strong) UISlider *slider; // 播放进度条
@property (nonatomic, strong) UIProgressView *progressView; //缓冲进度条
@property (nonatomic, strong) UILabel *currentTimeLabel; // 当前播放时长
@property (nonatomic, strong) UILabel *totalTimeLabel; // 总时长
@property (nonatomic, strong) UIActivityIndicatorView *activityView; // 菊花旋转等待

@property (nonatomic, assign) CGFloat startPlayPoint;
@property (nonatomic, assign) CGFloat current;// 当前时长
@property (nonatomic, assign) CGFloat total; // 总时长


@property (nonatomic, strong) NSBundle *imageBundle;

@property (nonatomic, assign) ZJVideoScreenRatio scrennRatio;


@end

@implementation doZJVideoView

- (instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url startPlayPoint:(NSInteger)startPlayPoint{
    
    if(self == [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor blackColor];
        self.userInteractionEnabled = YES;
        _initFrame = frame;
        _isShowBar = 1;
        
        _startPlayPoint = startPlayPoint;
        _scrennRatio = ZJVideoScreenRatioCover;
        // 初始化avplyer
        AVPlayer *player = [AVPlayer playerWithURL:url];
        self.avPlayer = player;
        // 添加通知
        [self addNotification];
        // 添加观察者
        [self addObserverForAVPlayer];
        // 初始化UI
        [self setupUI];
    }
    return self;
}

- (void)dealloc{
    [self removeObserverAndNotification];
    if (self.videoLayer) {
        [self.videoLayer removeFromSuperlayer];
    }
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    self.avPlayer = nil;
}

#pragma mark - UI操作

- (void)setupUI{
    [self.layer addSublayer:self.videoLayer];
    
    [self.topToolBar addSubview:self.closeBtn];
    [self.topToolBar addSubview:self.halfBtn];
    [self.topToolBar addSubview:self.threeQuartersBtn];
    [self.topToolBar addSubview:self.coveredBtn];
    [self addSubview:self.topToolBar];

    [self.bottomToolBar addSubview:self.playBtn];
    [self.bottomToolBar addSubview:self.fullScreenBtn];
    [self.bottomToolBar addSubview:self.currentTimeLabel];
    [self.bottomToolBar addSubview:self.totalTimeLabel];
    [self.bottomToolBar addSubview:self.progressView];
    [self.bottomToolBar addSubview:self.slider];
    [self addSubview:self.bottomToolBar];
    
    [self addSubview:self.activityView];
    
    self.playBtn.selected = true;

    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self addGestureRecognizer:tap];
    
}

- (void)updateFrame:(BOOL)isFull{
    
    if (isFull == 1) {
        self.frame = CGRectMake(0,0,ZJScreenHeight,ZJScreenWidth);

        self.topToolBar.frame = CGRectMake(0, 0 , ZJVIDEOVIEWHEIGHT, ZJTopToolBarH);
        self.bottomToolBar.frame = CGRectMake(0, ZJVIDEOVIEWWIDTH - ZJBottomToolBarH, ZJVIDEOVIEWHEIGHT, ZJBottomToolBarH);
        
        _fullScreenBtn.frame = CGRectMake(ZJVIDEOVIEWHEIGHT - ZJToolBarHorizontalGap - FullScreenBtnW, ZJToolBarVerticalGap, FullScreenBtnW, FullScreenBtnH);

        _activityView.center = CGPointMake(ZJVIDEOVIEWHEIGHT/2, ZJVIDEOVIEWWIDTH/2);
        
        
    }else{
        self.frame = CGRectMake(0,0,ZJScreenWidth,ZJScreenHeight);
        self.topToolBar.frame = CGRectMake(0, 0 , ZJVIDEOVIEWWIDTH, ZJTopToolBarH);
        self.bottomToolBar.frame = CGRectMake(0, ZJVIDEOVIEWHEIGHT - ZJBottomToolBarH, ZJVIDEOVIEWWIDTH, ZJBottomToolBarH);
        
        _fullScreenBtn.frame = CGRectMake(ZJVIDEOVIEWWIDTH - ZJToolBarHorizontalGap - FullScreenBtnW, ZJToolBarVerticalGap, FullScreenBtnW, FullScreenBtnH);
        
        _activityView.center = CGPointMake(ZJVIDEOVIEWWIDTH/2, ZJVIDEOVIEWHEIGHT/2);
        
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _videoLayer.frame = self.bounds;
    if (isFull) {
        [self adjustVideoScreenRatio];
    }
    [CATransaction commit];
    _playBtn.frame = CGRectMake(ZJToolBarHorizontalGap, ZJToolBarVerticalGap, PlayBtnW, PlayBtnH);
    _totalTimeLabel.frame = CGRectMake(self.fullScreenBtn.frame.origin.x - ZJToolBarHorizontalGap - TimeLabelW, self.fullScreenBtn.frame.origin.y, TimeLabelW, TimeLabelH);
    _currentTimeLabel.frame = CGRectMake(self.totalTimeLabel.frame.origin.x - TimeLabelW,self.playBtn.frame.origin.y,TimeLabelW,TimeLabelH);
    _progressView.frame = CGRectMake(CGRectGetMaxX(self.playBtn.frame) + ZJToolBarHorizontalGap ,ZJBottomToolBarH/2,self.currentTimeLabel.frame.origin.x - ZJToolBarHorizontalGap * 2 - CGRectGetMaxX(self.playBtn.frame),ProgressViewH);
    _slider.frame = CGRectMake(self.progressView.frame.origin.x - 2,ProgressViewH,self.progressView.frame.size.width + 3,ZJBottomToolBarH);
    
}


#pragma mark - 通知/KVO监听

/// 添加通知
- (void)addNotification{
    
    //监测屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
    //添加AVPlayerItem播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //添加AVPlayerItem开始缓冲通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bufferStart:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

// KOV监控 播放器进度更新
- (void)addObserverForAVPlayer
{
    //监控播放速率
    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    
    AVPlayerItem *playerItem = self.avPlayer.currentItem;
    //监控状态属性(AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态)
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    //监控网络加载缓冲情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监控是否可播放
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    
    //播放进度观察者  //设置每0.1秒执行一次
    __weak typeof(self) weakSelf = self;
    _playerTimeObserver =  [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (weakSelf.dragSlider) {
            return ;
        }
        
        CGFloat current = CMTimeGetSeconds(time);
        weakSelf.current = current;
        CMTime totalTime = weakSelf.avPlayer.currentItem.duration;
        CGFloat total = CMTimeGetSeconds(totalTime);
        weakSelf.total = total;
        weakSelf.slider.value = current/total;
        weakSelf.currentTimeLabel.text = [weakSelf timeFormatted:current];
        weakSelf.totalTimeLabel.text = [NSString stringWithFormat:@"/%@",[weakSelf timeFormatted:total]] ;
        
    }];
}

/// 移除KVO监控和观察者
- (void)removeObserverAndNotification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

    
    [self.avPlayer removeObserver:self forKeyPath:@"rate"];
    
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    [self.avPlayer removeTimeObserver:_playerTimeObserver];
    _playerTimeObserver = nil;
}

- (NSString *)timeFormatted:(int)Seconds
{
    int seconds = Seconds % 60;
    int minutes = (Seconds / 60) % 60;
    //int hours = Seconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}
/// 通过KVO监控回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        //监控网络加载情况属性
        NSArray *array = self.avPlayer.currentItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //现有缓冲总长度
        CGFloat totalBuffer = startSeconds + durationSeconds;
        //视频总时长
        CMTime totalTime = self.avPlayer.currentItem.duration;
        CGFloat total = CMTimeGetSeconds(totalTime);
        if (totalBuffer/total <= 1.0 ) {
            [self.progressView setProgress:totalBuffer/total animated:YES];
        }
        
    }else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        
        if (self.avPlayer.currentItem.playbackLikelyToKeepUp == YES) {
            
            if (_activityView != nil) {
                self.playBtn.selected = false;
                [self.activityView stopAnimating];
                [self.activityView removeFromSuperview];
                _activityView = nil;
            }
        }
    }else if ([keyPath isEqualToString:@"status"]){
        
        //监控状态属性
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        
        switch ((status)) {
            case AVPlayerStatusReadyToPlay:
                [self play];
                ZJLog(@"准备播放");
                break;
            case AVPlayerStatusUnknown:
                
                break;
            case AVPlayerStatusFailed:
                
                break;
                
        }
    }else if ([keyPath isEqualToString:@"rate"]){
        if (self.avPlayer.rate == 1) {
        }
    }
    
}

#pragma mark - Events Handle

/**
 asset load ready,start to play
 */
- (void)play {
    if (self.startPlayPoint == 0) {
        [self.avPlayer play];
//        self.playBtn.selected = false; // 这里定位不准确 改为在playbackLikelyToKeepUp逻辑处更改.
    }else {
        CGFloat totalMillisecond = self.avPlayer.currentItem.duration.value / self.avPlayer.currentItem.duration.timescale * 1000.0;
        CGFloat pointToSeek = self.startPlayPoint <= totalMillisecond ? self.startPlayPoint / 1000 : 0;
        
        CMTime totalTime = self.avPlayer.currentItem.duration;
        CGFloat total = CMTimeGetSeconds(totalTime);
        
        self.currentTimeLabel.text = [self timeFormatted:pointToSeek];
        self.slider.value = pointToSeek / total;

        // 精确时间点播放
        [self.avPlayer seekToTime:CMTimeMake(pointToSeek, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            if (finished) {
               [self.avPlayer play];
                self.playBtn.selected = false;
            }
        }];
        
    }
}

/// 播放完成
- (void)playFinished:(NSNotification *)notification{
    
    [self.playBtn setImage:[self getImageWithImageName:@"do_zjvideoview_play"] forState:UIControlStateNormal];
    self.playBtn.selected = true;
    
    if(self.playFinishedBlock){
        self.playFinishedBlock();
    } else if ([_delegate respondsToSelector:@selector(doZJVideoViewPlayFinished:)]){
        [_delegate doZJVideoViewPlayFinished:self];
    }
    
}

/// 缓冲开始回调
- (void)bufferStart:(NSNotification *)notification{
    
    [self addSubview:self.activityView];
    
}

/// 根据设备方向旋转屏幕
- (void)orientationChange:(NSNotification *)notification{
    
    UIDeviceOrientation  orientation = [UIDevice currentDevice].orientation;
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            
            _halfBtn.hidden = true;
            _threeQuartersBtn.hidden = true;
            _coveredBtn.hidden = true;
            
            [self autoDeviceOrientation:UIDeviceOrientationPortrait];
            break;
        case UIDeviceOrientationLandscapeLeft:
            _videoLayer.videoGravity =  AVLayerVideoGravityResizeAspectFill;
            _halfBtn.hidden = false;
            _threeQuartersBtn.hidden = false;
            _coveredBtn.hidden = false;
            
            [self autoDeviceOrientation:UIDeviceOrientationLandscapeLeft];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            
            break;
        case UIDeviceOrientationLandscapeRight:
            _videoLayer.videoGravity =  AVLayerVideoGravityResizeAspectFill;
            _halfBtn.hidden = false;
            _threeQuartersBtn.hidden = false;
            _coveredBtn.hidden = false;

            [self autoDeviceOrientation:UIDeviceOrientationLandscapeRight];
            break;
    }
    
}

- (void)autoDeviceOrientation:(UIDeviceOrientation)orientation{
    
    if (orientation == UIDeviceOrientationPortrait) {
        
        if (self.straightFull) {
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = CGAffineTransformMakeRotation(M_PI_2);
            }completion:^(BOOL finished) {
                [self updateFrame:1];
            }];
            
            [self.fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomOut"] forState:UIControlStateNormal];
            _isFullScreen = 1;
            
            
        }else{
            //非全屏
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = CGAffineTransformIdentity;
                [self updateFrame:0];
            }completion:^(BOOL finished) {
                
            }];
            
            [self.fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomIn"] forState:UIControlStateNormal];
            _isFullScreen = 0;
        }
        
    }else if(orientation == UIDeviceOrientationLandscapeLeft){
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }completion:^(BOOL finished) {
            [self updateFrame:1];
        }];
        
        [self.fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomOut"] forState:UIControlStateNormal];
        _isFullScreen = 1;
        
    }else if(orientation == UIDeviceOrientationLandscapeRight){

        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }completion:^(BOOL finished) {
            [self updateFrame:1];
        }];
        
        [self.fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomOut"] forState:UIControlStateNormal];
        _isFullScreen = 1;
        
    }else{
    }
    
    if (self.fullScreenBlock) {
        self.fullScreenBlock(_isFullScreen);
    } else if ([_delegate respondsToSelector:@selector(doZJVideoViewFullScreen:withIsFull:)]) {
        [_delegate doZJVideoViewFullScreen:self withIsFull:_isFullScreen];
    }
    
}

- (void)playBtnClicked:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        [self.avPlayer pause];
        
    }else{
        
        if (self.current == self.total) {
            [self.avPlayer seekToTime: CMTimeMake(0,1) completionHandler:^(BOOL finished) {
            }];
        }
        [self.avPlayer play];
    }

}

- (void)coloseBtnClicked:(UIButton *)btn{
    
    [self.avPlayer pause];
    
    if ([_delegate respondsToSelector:@selector(doZJVideoViewClose:)]){
        
        [self autoDeviceOrientation:UIDeviceOrientationPortrait];
        [_delegate doZJVideoViewClose:self];
    }
}


- (void)fullScreenBtnClicked:(UIButton *)fullScreenBtn{
    
    if (_isFullScreen == 0) {
        _videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _halfBtn.hidden = false;
        _threeQuartersBtn.hidden = false;
        _coveredBtn.hidden = false;
        
        // UIViewControler shouldAutorotate 为YES时无效
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }completion:^(BOOL finished) {
            [self updateFrame:1];
        }];
        [fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomOut"] forState:UIControlStateNormal];
        _isFullScreen = 1;
        
        
    }else{
        _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _halfBtn.hidden = true;
        _threeQuartersBtn.hidden = true;
        _coveredBtn.hidden = true;
        
        //非全屏
        // UIViewControler shouldAutorotate 为YES时无效
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            [self updateFrame:0];
        }completion:^(BOOL finished) {
            
        }];
        
        [fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomIn"] forState:UIControlStateNormal];
        _isFullScreen = 0;
        
    }
    
    if (self.fullScreenBlock) {
        self.fullScreenBlock(_isFullScreen);
    } else if ([_delegate respondsToSelector:@selector(doZJVideoViewFullScreen:withIsFull:)]) {
        [_delegate doZJVideoViewFullScreen:self withIsFull:_isFullScreen];
    }
    
}

- (void)sliderChange:(UISlider *)slider{
    
    _dragSlider = YES;
    self.playBtn.selected = true;
    [self.avPlayer pause];
    
    CMTime totalTime = self.avPlayer.currentItem.duration;
    CGFloat total = CMTimeGetSeconds(totalTime);
    self.currentTimeLabel.text = [self timeFormatted:(slider.value * total)];
    [self.avPlayer seekToTime: CMTimeMake(slider.value * total,1) completionHandler:^(BOOL finished) {
    }];
    
    
}

- (void)sliderChangeEnd:(UISlider *)slider{
    
    _dragSlider = NO;
    self.playBtn.selected = false;
    [self.avPlayer play];
}


- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tap{
    // 过滤底部工具栏区域点的点击事件
    CGPoint touchPoint = [tap locationInView:self];
    CGPoint touchPointInBottom = [self convertPoint:touchPoint toView:self.bottomToolBar];
    if ([self.bottomToolBar pointInside:touchPointInBottom withEvent:nil]) {
        return;
    }
    
    if(_isShowBar){
        self.topToolBar.hidden = YES;
        self.bottomToolBar.hidden = YES;
        _isShowBar = 0;
    }else{
        self.topToolBar.hidden = NO;
        self.bottomToolBar.hidden = NO;
        _isShowBar = 1;
    }
    if (self.showBarBlock) {
        self.showBarBlock(_isShowBar);
    }else if ([_delegate respondsToSelector:@selector(doZJVideoViewShowBar:withIsShow:)]) {
        [_delegate doZJVideoViewShowBar:self withIsShow:_isShowBar];
    }
}

/// app退到后台
- (void)appWillEnterBackground{
    
    [self.avPlayer pause];
    if (self.playBtn.selected ) {
        [self.playBtn setImage:[self getImageWithImageName:@"do_zjvideoview_play"] forState:UIControlStateNormal];
    }else{
        [self.playBtn setImage:[self getImageWithImageName:@"do_zjvideoview_pause"] forState:UIControlStateNormal];
    }
    
}

/// app进入前台
- (void)appWillEnterPlayGround{
    
    if (!self.playBtn.selected) {
        [self.avPlayer pause];
    }else{
        [self.avPlayer play];
    }
}

- (void)halfBtnClick {
    if (_halfBtn.selected)return;
    self.videoLayer.bounds = CGRectMake(0, 0, self.frame.size.height * 0.5, self.frame.size.width * 0.5);
    _halfBtn.selected = !_halfBtn.selected;
    if (_halfBtn.selected) {
        _coveredBtn.selected = false;
        _threeQuartersBtn.selected = false;
        _scrennRatio = ZJVideoScreenRatioHalf;
    }

}

- (void)threeQuartersBtnClick {
    if (_threeQuartersBtn.selected)return;
    self.videoLayer.bounds = CGRectMake(0, 0, self.frame.size.height * 0.75, self.frame.size.width * 0.75);
    _threeQuartersBtn.selected = !_threeQuartersBtn.selected;
    if (_threeQuartersBtn.selected) {
        _halfBtn.selected = false;
        _coveredBtn.selected = false;
        _scrennRatio = ZJVideoScreenRatioThreeQuarters;

    }
}

- (void)coveredBtnClick {
    if (_coveredBtn.selected)return;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.videoLayer.bounds = CGRectMake(0, 0, self.frame.size.height, self.frame.size.width);
    [CATransaction commit];

    _coveredBtn.selected = !_coveredBtn.selected;
    if (_coveredBtn.selected) {
        _halfBtn.selected = false;
        _threeQuartersBtn.selected = false;
        _scrennRatio = ZJVideoScreenRatioCover;

    }
}

- (void)adjustVideoScreenRatio {
    float WIDTH = self.frame.size.height;
    float HEIGHT = self.frame.size.width;
    switch (_scrennRatio) {
        case ZJVideoScreenRatioCover: {
            WIDTH *= 1.0f;
            HEIGHT *= 1.0f;
            break;
        }
        case ZJVideoScreenRatioThreeQuarters: {
            WIDTH *= 0.75f;
            HEIGHT *= 0.75f;
            break;
        }
        case ZJVideoScreenRatioHalf: {
            WIDTH *= 0.5f;
            HEIGHT *= 0.5f;
            break;
        }
        default: {
            WIDTH *= 1.0f;
            HEIGHT *= 1.0f;
            break;
        }
    }
    self.videoLayer.bounds = CGRectMake(0, 0, WIDTH, HEIGHT);
}
#pragma mark - lazy get method

- (AVPlayerLayer *)videoLayer {
    if (_videoLayer == nil) {
        // 显示图像的
        _videoLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        // 锚点的坐标
        _videoLayer.position = CGPointMake(ZJVIDEOVIEWWIDTH/2, ZJVIDEOVIEWHEIGHT/2);
        _videoLayer.bounds = CGRectMake(0, 0, ZJVIDEOVIEWWIDTH, ZJVIDEOVIEWHEIGHT);
        // 锚点
        _videoLayer.anchorPoint = CGPointMake(0.5, 0.5);
        _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        return _videoLayer;
    }
    
    return _videoLayer;
}

- (UIView *)topToolBar{
    
    if (_topToolBar == nil) {
        _topToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ZJVIDEOVIEWWIDTH, ZJTopToolBarH)];
        _topToolBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    }
    return _topToolBar;
}

- (UIButton *)closeBtn{
    
    if (_closeBtn == nil) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(CloseBtnLeftTopGap, CloseBtnLeftTopGap, CloseBtnW, CloseBtnH)];
        [_closeBtn setImage:[self getImageWithImageName:@"do_zjvideoview_close"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(coloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIButton *)halfBtn {
    if (_halfBtn == nil) {
        _halfBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.height - 50 - CloseBtnLeftTopGap, CloseBtnLeftTopGap, 50, 35)];
        [_halfBtn setTitle:@"50%" forState:UIControlStateNormal];
        [_halfBtn setTitleColor:[UIColor colorWithRed:0 green:85/255.0f blue:142/255.0f alpha:1.0] forState:UIControlStateSelected];
        _halfBtn.selected = false;
        _halfBtn.hidden = true;
        [_halfBtn addTarget:self action:@selector(halfBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _halfBtn;
}

- (UIButton *)threeQuartersBtn {
    if (_threeQuartersBtn == nil) {
        _threeQuartersBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.halfBtn.frame.origin.x - 10 - 50, CloseBtnLeftTopGap, 50, 35)];
        [_threeQuartersBtn setTitle:@"75%" forState:UIControlStateNormal];
        [_threeQuartersBtn setTitleColor:[UIColor colorWithRed:0 green:85/255.0f blue:142/255.0f alpha:1.0] forState:UIControlStateSelected];
        _threeQuartersBtn.selected = false;
        _threeQuartersBtn.hidden = true;
        [_threeQuartersBtn addTarget:self action:@selector(threeQuartersBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _threeQuartersBtn;
}

- (UIButton *)coveredBtn {
    if (_coveredBtn == nil) {
        _coveredBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.threeQuartersBtn.frame.origin.x - 10 - 50, CloseBtnLeftTopGap, 50, 35)];
        [_coveredBtn setTitle:@"满屏" forState:UIControlStateNormal];
        [_coveredBtn setTitleColor:[UIColor colorWithRed:0 green:85/255.0f blue:142/255.0f alpha:1.0] forState:UIControlStateSelected];
        _coveredBtn.selected = true;
        _threeQuartersBtn.hidden = true;
        [_coveredBtn addTarget:self action:@selector(coveredBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _coveredBtn;
}

- (UIView *)bottomToolBar{
    
    if (_bottomToolBar == nil) {
        _bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, ZJVIDEOVIEWHEIGHT - ZJBottomToolBarH, ZJVIDEOVIEWWIDTH, ZJBottomToolBarH)];
        _bottomToolBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    }
    return _bottomToolBar;
}

- (UIButton *)playBtn{
    
    if (_playBtn == nil) {
        _playBtn = [[UIButton alloc] initWithFrame:CGRectMake(ZJToolBarHorizontalGap, ZJToolBarVerticalGap, PlayBtnW, PlayBtnH)];
        [_playBtn setImage:[self getImageWithImageName:@"do_zjvideoview_play"] forState:UIControlStateNormal];
        [_playBtn setImage:[self getImageWithImageName:@"do_zjvideoview_pause"] forState:UIControlStateSelected];

        [_playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)fullScreenBtn{
    
    if (_fullScreenBtn == nil) {
        
        _fullScreenBtn = [[UIButton alloc] initWithFrame:CGRectMake(ZJVIDEOVIEWWIDTH - ZJToolBarHorizontalGap - FullScreenBtnW, ZJToolBarVerticalGap, FullScreenBtnW, FullScreenBtnH)];
        [_fullScreenBtn setImage:[self getImageWithImageName:@"do_zjvideoview_zoomIn"] forState:UIControlStateNormal];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _fullScreenBtn;
}

- (UILabel *)totalTimeLabel{
    if (_totalTimeLabel == nil) {
        _totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.fullScreenBtn.frame.origin.x - ZJToolBarHorizontalGap - TimeLabelW, self.fullScreenBtn.frame.origin.y, TimeLabelW, TimeLabelH)];
        _totalTimeLabel.text = @"/00.00";
        _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        _totalTimeLabel.font = [UIFont systemFontOfSize:13];
        _totalTimeLabel.textColor = [UIColor whiteColor];
    }
    return _totalTimeLabel;
}

- (UILabel *)currentTimeLabel{
    if (_currentTimeLabel == nil) {
        _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.totalTimeLabel.frame.origin.x - TimeLabelW,self.playBtn.frame.origin.y,TimeLabelW,TimeLabelH)];
        _currentTimeLabel.text = @"00.00";
        _currentTimeLabel.textAlignment = NSTextAlignmentRight;
        _currentTimeLabel.font = [UIFont systemFontOfSize:13];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        
    }
    return _currentTimeLabel;
}

- (UIProgressView *)progressView{
    if (_progressView == nil) {
        //缓冲进度条
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(CGRectGetMaxX(self.playBtn.frame) + ZJToolBarHorizontalGap ,ZJBottomToolBarH/2,self.currentTimeLabel.frame.origin.x - ZJToolBarHorizontalGap * 2 - CGRectGetMaxX(self.playBtn.frame),ProgressViewH);
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [UIColor grayColor];
        _progressView.progress = 0.0;
    }
    return _progressView;
}

- (UISlider *)slider{
    if (_slider == nil) {
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x - 2,ProgressViewH,self.progressView.frame.size.width + 3,ZJBottomToolBarH)];
        [_slider setThumbImage:[self getImageWithImageName:@"do_zjvideoview_slider"] forState:UIControlStateNormal];
        _slider.value = 0.0;
        _slider.minimumValue = 0.0;
        _slider.maximumValue = 1.0;
        _slider.minimumTrackTintColor = [UIColor colorWithRed:0 green:85/255.0f blue:142/255.0f alpha:1.0];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        [_slider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged | UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(sliderChangeEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    }
    return _slider;
}


- (UIActivityIndicatorView *)activityView{
    
    if (_activityView == nil) {
        
        _activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 40 , 40)];
        _activityView.center = CGPointMake(ZJVIDEOVIEWWIDTH/2, ZJVIDEOVIEWHEIGHT/2);
        [_activityView startAnimating];
    }
    
    return _activityView;
    
}

- (NSBundle *)imageBundle {
    if (_imageBundle == nil) {
        NSURL *bundleUrl = [[NSBundle mainBundle] URLForResource:@"doZJVideoViewImage" withExtension:@"bundle"];
        _imageBundle = [NSBundle bundleWithURL:bundleUrl];
        return _imageBundle;
    }
    return _imageBundle;
}

- (UIImage*)getImageWithImageName:(NSString *)name{
    NSString *bundlePath = [self.imageBundle bundlePath];
    NSString *imgPath = [bundlePath stringByAppendingPathComponent:name];
    NSString *pathExtension = [imgPath pathExtension];
    //没有后缀加上PNG后缀
    if (!pathExtension || pathExtension.length == 0) {
        pathExtension = @"png";
    }
    NSString *imageName = nil;
    imageName = [NSString stringWithFormat:@"%@.%@", [[imgPath lastPathComponent] stringByDeletingPathExtension], pathExtension];
    return [UIImage imageWithContentsOfFile:[[imgPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:imageName]];
}

@end
