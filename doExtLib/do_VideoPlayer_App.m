//
//  do_VideoPlayer_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_VideoPlayer_App.h"
static do_VideoPlayer_App* instance;
@implementation do_VideoPlayer_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_VideoPlayer_App alloc]init];
    return instance;
}
@end
