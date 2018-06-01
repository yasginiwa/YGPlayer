//
//  YGPlayerView.h
//  Demo
//
//  Created by LiYugang on 2018/3/5.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class YGPlayInfo;

@interface YGPlayerView : UIView
@property (nonatomic, strong) NSNumber *leftConstraint;
@property (nonatomic, strong) NSNumber *topConstraint;
@property (nonatomic, strong) NSNumber *widthConstraint;
@property (nonatomic, strong) NSNumber *heightConstraint;
- (void)playWithPlayInfo:(YGPlayInfo *)playInfo;
@end
