//
//  ViewController.m
//  Demo
//
//  Created by LiYugang on 2018/3/5.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import "ViewController.h"
#import "YGPlayerView.h"
#import "YGVideoTool.h"
#import "YGPlayInfo.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *playInfos;
@end

@implementation ViewController

#pragma mark - 懒加载
- (NSMutableArray *)playInfos
{
    if (_playInfos == nil) {
        _playInfos = [YGVideoTool playInfos];
    }
    return _playInfos;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPlayerView];
}


- (void)didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning-------");
}

// 初始化播放器View
- (void)setupPlayerView
{
    YGPlayerView *playerView = [[[NSBundle mainBundle] loadNibNamed:@"YGPlayerView" owner:nil options:nil] lastObject];
    [self.view addSubview:playerView];
    YGPlayInfo *playInfo = [self.playInfos firstObject];
    [playerView playWithPlayInfo:playInfo];
}

@end
