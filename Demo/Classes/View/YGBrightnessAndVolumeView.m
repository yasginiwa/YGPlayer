//
//  YGBrightnessAndVolumeView.m
//  Demo
//
//  Created by YGLEE on 2018/2/15.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import "YGBrightnessAndVolumeView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#define YGGridCount 16

@interface YGBrightnessEchoView : UIView
@property (nonatomic, strong) NSMutableArray *gridArray;
@property (nonatomic, weak) UIToolbar *toolbar;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIImageView *bgImageView;
@property (nonatomic, weak) UIView *brightnessProgressView;
@property (nonatomic, assign) CGFloat currentBrightness;
@end

@implementation YGBrightnessEchoView

// 回显View单例
static id _instance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)sharedBrightnessEchoView
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - 懒加载
- (NSMutableArray *)gridArray
{
    if (_gridArray == nil) {
        _gridArray = [NSMutableArray array];
    }
    return _gridArray;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        // 初始化亮度回显图标
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        self.alpha = .0f;
        
        // UIToolbar用做毛玻璃背景
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.backgroundColor = [UIColor lightGrayColor];
        toolbar.alpha = 0.9;
        [self addSubview:toolbar];
        self.toolbar = toolbar;
        
        // 亮度回显图标标题
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        titleLabel.textColor = [UIColor colorWithRed:66/255.0 green:66/255.0f blue:66/255.0 alpha:1.00f];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = @"亮度";
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        // 亮度回显图标背景图片
        UIImageView *bgImageView = [[UIImageView alloc] init];
        bgImageView.image = [UIImage imageNamed:@"playerBrightness"];
        [self addSubview:bgImageView];
        self.bgImageView = bgImageView;
        
        // 亮度回显图标进度条
        UIView *brightnessProgressView = [[UIView alloc] init];
        brightnessProgressView.backgroundColor = [UIColor colorWithRed:66/255.0 green:66/255.0f blue:66/255.0 alpha:1.00f];
        [self addSubview:brightnessProgressView];
        self.brightnessProgressView = brightnessProgressView;
        
        // KVO 监控亮度的变化
        [self addObserver];
        
        [self setupBrightnessGrid];
    }
    return self;
}

- (void)setupBrightnessGrid
{
    for (int i = 0; i < 16; i++) {
        UIView *grid = [[UIView alloc] init];
        grid.backgroundColor = [UIColor whiteColor];
        [self.brightnessProgressView addSubview:grid];
        [self.gridArray addObject:grid];
    }
    [self updateBrightnessGrid:[UIScreen mainScreen].brightness];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // toolbar毛玻璃背景布局
    self.toolbar.frame = self.bounds;
    
    // 标题布局
    self.titleLabel.frame = CGRectMake(0, 5, self.bounds.size.width, 30);
    
    // 亮度图标布局
    self.bgImageView.frame = CGRectMake(38, CGRectGetMaxY(self.titleLabel.frame) + 5, 79, 76);
    
    // 亮度进度条布局
    CGRect brightnessProgressViewRect = self.brightnessProgressView.frame;
    brightnessProgressViewRect.origin.x = 12;
    brightnessProgressViewRect.origin.y = CGRectGetMaxY(self.bgImageView.frame) + 16;
    brightnessProgressViewRect.size.width = self.bounds.size.width - 2 * 12;
    brightnessProgressViewRect.size.height = 7;
    self.brightnessProgressView.frame = brightnessProgressViewRect;
    
    // 亮度进度条内小格子布局
    CGFloat gridW = (self.brightnessProgressView.bounds.size.width - (YGGridCount + 1)) / YGGridCount;
    CGFloat gridH = 5;
    CGFloat gridY = 1;
    
    for (int i = 0; i < YGGridCount; i++) {
        CGFloat gridX = i * (gridW + 1) + 1;
        UIView *gridView = self.gridArray[i];
        gridView.frame = CGRectMake(gridX, gridY, gridW, gridH);
    }
}

// 添加观察者
- (void)addObserver
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    [mainScreen addObserver:self forKeyPath:@"brightness" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    CGFloat brightness = [change[@"new"] floatValue];
    [self updateBrightnessGrid:brightness];
}

// 更新亮度回显
- (void)updateBrightnessGrid:(CGFloat)brightness
{
    CGFloat stage = 1 / 16.0;
    NSInteger level = brightness / stage;
    for (int i = 0; i < self.gridArray.count; i++) {
        UIView *grid = self.gridArray[i];
        if (i <= level) {
            grid.hidden = NO;
        } else {
            grid.hidden = YES;
        }
    }
}

- (void)dealloc
{
    [self removeObserver:[UIScreen mainScreen] forKeyPath:@"brightness"];
}
@end




@interface YGBrightnessAndVolumeView ()
@property (nonatomic, weak) UIView *brightnessView;
@property (nonatomic, weak) UIView *volumeView;
@property (nonatomic, assign) CGFloat currentBrightnessValue;
@property (nonatomic, assign) CGFloat currentVolumeValue;
@property (nonatomic, weak) UIView *brightnessEchoView;

@end

@implementation YGBrightnessAndVolumeView

// 单例
static id _instance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)sharedBrightnessAndAudioView
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

// 初始化 加入亮度View和音量View
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        // 初始化左边一半的亮度调节的View
        UIView *brightnessView = [[UIView alloc] init];
        brightnessView.backgroundColor = [UIColor clearColor];
        self.brightnessView = brightnessView;
        [self addSubview:brightnessView];
        [self addBrightnessPanGesture];

        // 初始化右边的音量调节的View
        UIView *volumeView = [[UIView alloc] init];
        volumeView.backgroundColor = [UIColor clearColor];
        [self addSubview:volumeView];
        self.volumeView = volumeView;
        [self addVolumePanGesture];
        
        // 初始化音量回显图标
        YGBrightnessEchoView *brightnessEchoView = [YGBrightnessEchoView sharedBrightnessEchoView];
        [self addSubview:brightnessEchoView];
        [self bringSubviewToFront:brightnessEchoView];
        self.brightnessEchoView = brightnessEchoView;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 布局亮度调节View
    [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self);
        make.width.mas_equalTo(self.bounds.size.width * 0.5);
    }];
    
    // 布局BrightnessEchoView
    [self.brightnessEchoView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(155.0);
        make.center.equalTo([UIApplication sharedApplication].keyWindow);
    }];
    
    // 布局音量调节View
    [self.volumeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(self);
        make.width.mas_equalTo(self.bounds.size.width * 0.5);
    }];
}

- (void)addBrightnessPanGesture
{
    UIPanGestureRecognizer *brightnessPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(brightnessChange:)];
    [self.brightnessView addGestureRecognizer:brightnessPan];
}

- (void)addVolumePanGesture
{
    UIPanGestureRecognizer *volumePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(volumeChange:)];
    [self.volumeView addGestureRecognizer:volumePan];
}

- (void)brightnessChange:(UIPanGestureRecognizer *)sender
{
    CGPoint panPoint = [sender translationInView:self.brightnessView];
    CGFloat delta = -panPoint.y / scrnW;
    self.currentBrightnessValue = [UIScreen mainScreen].brightness;
    if (self.currentVolumeValue < 0) self.currentVolumeValue = 0;
    [[UIScreen mainScreen] setBrightness:self.currentBrightnessValue + delta];

    [UIView animateWithDuration:.2f animations:^{
        [self showBrightnessEchoView];
    } completion:^(BOOL finished) {
        [self autoFadeoutBrightnessEchoView];
    }];
}

- (void)showBrightnessEchoView
{
    self.brightnessEchoView.alpha = 1.f;
}

- (void)hideBrightnessEchoView
{
    [UIView animateWithDuration:.5f animations:^{
        self.brightnessEchoView.alpha = .0f;
    }];
}

- (void)autoFadeoutBrightnessEchoView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(hideBrightnessEchoView) withObject:self afterDelay:3.f];
}

- (void)volumeChange:(UIPanGestureRecognizer *)sender
{
    CGPoint panPoint = [sender translationInView:self.volumeView];
    CGFloat delta = -panPoint.y / scrnW;
    MPVolumeView *sysVolumeView = [[MPVolumeView alloc] init];
    [sysVolumeView userActivity];
    
    // 遍历音量显示的回显View的子控件 找到音量大小的slider
    UISlider *sysVolumeSlider = nil;
    for (UIView *newView in sysVolumeView.subviews) {
        if ([[newView class].description isEqualToString:@"MPVolumeSlider"]) {
            sysVolumeSlider = (UISlider *)newView;
            break;
        }
    }
    self.currentVolumeValue = [[AVAudioSession sharedInstance] outputVolume];
    sysVolumeSlider.value = self.currentVolumeValue + delta;
    if (sysVolumeSlider.value < 0) sysVolumeSlider.value = 0.0;
}

- (void)dealloc
{
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
}
@end
