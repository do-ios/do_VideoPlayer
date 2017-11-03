//
//  do_VideoPlayer_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_VideoPlayer_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doLogEngine.h"
#import "doIOHelper.h"
#import "doIPage.h"

#import "doZJVideoViewController.h"
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




@implementation do_VideoPlayer_SM

- (void)OnInit {
    [super OnInit];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:true error:nil];
}


#pragma mark- private method
/**
 whether is local resource
 */
- (BOOL)isLocalFilePath:(NSString*)path {
    if ([path hasPrefix:@"data://"] || [path hasPrefix:@"source://"]) {
        return true;
    }
    return false;
}
/**
 whether is legal http resource
 */
- (BOOL)isLegalHttpPath:(NSString*)path {
    if ([path hasPrefix:@"http://"] || [path hasPrefix:@"https://"] || [path hasPrefix:@"www."]) {
        return true;
    }
    return false;
}

/**
 log error info
 */
- (void)logErrorInfo:(NSString*)errorStr {
    NSString *error = [NSString stringWithFormat:@"do_VideoPlayer \'play\' method -> %@",errorStr];
    ZJLog(@"%@",error);
    [[doServiceContainer Instance].LogEngine WriteError:nil :error];
}

#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
- (void)play:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    
    NSString *urlPath = [doJsonHelper GetOneText:_dictParas :@"path" :nil];
    NSInteger startPlayPoint = [doJsonHelper GetOneInteger:_dictParas :@"point" :0];
    
    if (!urlPath) {
        [self logErrorInfo:@"path参数必传"];
        return;
    }else {
        if ([urlPath isEqualToString:@""]) {
            [self logErrorInfo:@"path参数不能为空字符串"];
            return;
        }else {
            if ([urlPath hasPrefix:@"initdata://"]) { // 不支持initdata目录
                [[doServiceContainer Instance].LogEngine WriteError:nil :@"iOS不支持initdata目录"];
                return;
            }
            NSURL *videoUrl;
            if ([self isLocalFilePath:urlPath]) { // 本地音频路径
                urlPath = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentPage.CurrentApp :urlPath];
                videoUrl = [NSURL fileURLWithPath:urlPath];
            }else if([self isLegalHttpPath:urlPath]){
                videoUrl = [NSURL URLWithString:urlPath];
            }else {
                [self logErrorInfo:@"path路径:不是一个合法的本地路径(source://、data://)或者网络路径"];
                return;
            }
            
            if (!videoUrl) { // url初始化失败
                [self logErrorInfo:@"path路径:本地路径(source://、data://)或者网络路径对应的视频资源不存在"];
                return;
            }else { // url初始化成功
                UIViewController *currentVC =(UIViewController*)_scritEngine.CurrentPage.PageView;
                doZJVideoViewController *videoViewVC = [[doZJVideoViewController alloc] init];
                videoViewVC.videoUrl = videoUrl;
                videoViewVC.startPlayPoint = startPlayPoint;
                //                [currentVC.navigationController pushViewController:videoViewVC animated:false];
                [currentVC presentViewController:videoViewVC animated:YES completion:nil];
            }
            
        }
    }
    
    
}
//异步

@end
