//
//  YGLoadingView.h
//  Demo
//
//  Created by YGLEE on 2018/3/28.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YGLoadingView : UIView
@property (nonatomic, assign) BOOL hidesWhenStopped;
- (void)startAnimating;
- (void)stopAnimating;
@end
