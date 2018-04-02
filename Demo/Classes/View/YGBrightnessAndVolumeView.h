//
//  YGBrightnessAndVolumeView.h
//  皇冠直播
//
//  Created by YGLEE on 2018/2/15.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YGBrightnessAndVolumeView : UIView
@property (nonatomic, copy) void(^progressChangeHandle)(CGFloat);
@property (nonatomic, copy) void(^progressChangeEnd)(void);
+ (instancetype)sharedBrightnessAndAudioView;
@end
