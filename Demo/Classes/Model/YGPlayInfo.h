//
//  YGPlayInfo.h
//  Demo
//
//  Created by LiYugang on 2018/3/6.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YGPlayInfo : NSObject
// 曲目url
@property (nonatomic, copy) NSString *url;
// 曲目歌手
@property (nonatomic, copy) NSString *artist;
// 曲目名称
@property (nonatomic, copy) NSString *title;
// 视频占位图
@property (nonatomic, copy) NSString *placeholder;
@end
