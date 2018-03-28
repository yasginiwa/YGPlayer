//
//  YGVideoTool.m
//  Demo
//
//  Created by LiYugang on 2018/3/6.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import "YGVideoTool.h"
#import "YGPlayInfo.h"
#import "MJExtension.h"

static NSMutableArray *_playInfos;

@implementation YGVideoTool

static id _instance;

// 单例
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)sharedVideoTool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

// 字典数据转成模型
+ (NSMutableArray *)playInfos
{
    if (_playInfos == nil) {
        _playInfos = [YGPlayInfo mj_objectArrayWithFilename:@"playList.plist"];
    }
    return _playInfos;
}
@end
