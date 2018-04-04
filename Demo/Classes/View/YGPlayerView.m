//
//  YGPlayerView.m
//  Demo
//
//  Created by LiYugang on 2018/3/5.
//  Copyright © 2018年 LiYugang. All rights reserved.
//

#import "YGPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "YGPlayInfo.h"
#import "YGVideoTool.h"
#import "NSString+Time.h"
#import "YGBrightnessAndVolumeView.h"
#import "YGLoadingView.h"

@interface YGPreviewView : UIView
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UILabel *previewtitleLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIProgressView *progressView;
+ (instancetype)sharedPreviewView;
@end

@implementation YGPreviewView
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

+ (instancetype)sharedPreviewView
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - 懒加载
// 视频缩略图
- (UIImageView *)previewImageView
{
    if (_previewImageView == nil) {
        _previewImageView = [[UIImageView alloc] init];
        _previewImageView.layer.cornerRadius = 5;
        _previewImageView.clipsToBounds = YES;
        _previewImageView.backgroundColor = [UIColor colorWithRed:.0f green:.0f blue:.0f alpha:.5f];
        [self addSubview:_previewImageView];
    }
    return _previewImageView;
}

// 进度标签
- (UILabel *)previewtitleLabel
{
    if (_previewtitleLabel == nil) {
        _previewtitleLabel = [[UILabel alloc] init];
        _previewtitleLabel.font = [UIFont systemFontOfSize:20];
        _previewtitleLabel.textColor = [UIColor whiteColor];
        _previewtitleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_previewtitleLabel];
    }
    return _previewtitleLabel;
}

- (UIProgressView *)progressView
{
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.trackTintColor = [UIColor whiteColor];
        _progressView.progressTintColor = [UIColor redColor];
        [self addSubview:_progressView];
    }
    return _progressView;
}

// 等待菊花
- (UIActivityIndicatorView *)loadingView
{
    if (_loadingView == nil) {
        _loadingView = [[UIActivityIndicatorView alloc] init];
        _loadingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        _loadingView.hidesWhenStopped = YES;
        [self.previewImageView addSubview:_loadingView];
    }
    return _loadingView;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.previewtitleLabel.text = title;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    if (image == nil) {
        [self.loadingView startAnimating];
        self.previewImageView.image = nil;
    } else {
        [self.loadingView stopAnimating];
        self.previewImageView.image = image;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) { // 转至竖屏
        self.previewImageView.hidden = YES;
        self.progressView.hidden = NO;
    } else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) { // 转至横屏
        self.previewImageView.hidden = NO;
        self.progressView.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self);
        make.height.equalTo(self).multipliedBy(9/16.0);
    }];

    [self.previewtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.previewImageView).offset(110.f);
        make.height.mas_equalTo(20.f);
    }];
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.previewImageView);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(100);
    }];
}
@end


@interface YGPlayerView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *playInfos;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) id timeObserver;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIProgressView *loadedView;
@property (weak, nonatomic) IBOutlet UIImageView *placeHolderView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic, strong) YGLoadingView *waitingView;
@property (weak, nonatomic) IBOutlet UIButton *centerPlayBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *rotateBtn;
@property (weak, nonatomic) IBOutlet UIButton *episodeBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *moreBtn;
@property (nonatomic, assign, getter=isLandscape) BOOL landscape;
@property (nonatomic, assign, getter=controlPanelIsShowing) BOOL controlPanelShow;
@property (nonatomic, weak) UIView *cover;
@property (nonatomic, weak) UIButton *episodeCover;
@property (nonatomic, weak) UIButton *replayBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottomConstaint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rotateBtnLeadingConstraint;
@property (nonatomic, weak) YGBrightnessAndVolumeView *brightnessAndVolumeView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGuesture;
@property (nonatomic, strong) YGPreviewView *previewView;
@property (nonatomic, strong) NSMutableArray *thumbImages;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, assign, getter=isEndedDrag) BOOL endedDrag;
@end

@implementation YGPlayerView

#pragma mark - 懒加载
- (NSMutableArray *)playInfos
{
    if (_playInfos == nil) {
        _playInfos = [YGPlayInfo mj_objectArrayWithFilename:@"playList.plist"];
    }
    return _playInfos;
}

- (YGLoadingView *)waitingView
{
    if (_waitingView == nil) {
        _waitingView = [[YGLoadingView alloc] init];
        _waitingView.hidesWhenStopped = YES;
        [self addSubview:_waitingView];
    }
    return _waitingView;
}

- (YGPreviewView *)previewView
{
    if (_previewView == nil) {
        _previewView = [YGPreviewView sharedPreviewView];
        [self addSubview:_previewView];
    }
    return _previewView;
}

- (NSMutableArray *)thumbImages
{
    if (_thumbImages == nil) {
        _thumbImages = [NSMutableArray array];
        [self addObserver:self forKeyPath:@"thumbImages" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return _thumbImages;
}

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    }
    return _imageGenerator;
}

// 从文件中加载控件时调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.progressSlider.value = 0.f;
        self.loadedView.progress = 0.f;
        [self addGesture];
        [self showOrHideControlPanel];
        [self setupBrightnessAndVolumeView];
    }
    return self;
}


// xib加载完毕调用
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"icmpv_thumb_light"] forState:UIControlStateNormal];
    self.progressSlider.value = .0f;
    self.loadedView.progress = .0f;
    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = @"00:00";
    
    [self.progressSlider addTarget:self action:@selector(progressDragEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    self.cover.frame = self.bounds;
    self.replayBtn.frame = CGRectMake(0, 0, 200, 155);
    self.replayBtn.center = self.center;
    self.brightnessAndVolumeView.frame = self.bounds;
    
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(180.f);
        make.height.mas_equalTo(180.f);
        make.center.equalTo(self);
    }];
    
    [self.waitingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.height.mas_equalTo(80.f);
    }];
    
    [self bringSubviewToFront:self.brightnessAndVolumeView];
    [self bringSubviewToFront:self.topView];
    [self bringSubviewToFront:self.bottomView];
    [self bringSubviewToFront:self.centerPlayBtn];
    [self bringSubviewToFront:self.waitingView];
    [self bringSubviewToFront:self.previewView];
    [self bringSubviewToFront:self.episodeCover];
    [self bringSubviewToFront:self.cover];
}

- (void)playWithPlayInfo:(YGPlayInfo *)playInfo
{
    // 清空缩略图数组
    [self.thumbImages removeAllObjects];
    
    // 重置player
    [self resetPlayer];
    
    // 切换隐藏控制面板
    [self showOrHideControlPanel];
    
    // 设置预览缩略图透明度为0
    self.previewView.alpha = .0f;
    
    // 存储当前播放URL到本地 以便后面选集时比较哪个是当前播放的曲目
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:playInfo.url forKey:@"currentPlayingUrl"];
    
    // 因为replaceCurrentItemWithPlayerItem在使用时会卡住主线程 重新创建player解决
    self.player = [self setupPlayer];
    self.asset = [AVURLAsset assetWithURL:[NSURL URLWithString:playInfo.url]];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
    
    // 添加时间周期OB、OB和通知
    [self addTimerObserver];
    [self addPlayItemObserverAndNotification];
    
    // 设置播放器标题
    self.titleLabel.text = playInfo.title;
    self.placeHolderView.hidden = NO;
    self.placeHolderView.image = [UIImage imageNamed:playInfo.placeholder];
    
    [self.waitingView startAnimating];
    
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    
    // 刚开始切换视频时 rate为0时显示视频海报(placeholder)
    if (self.player.rate > 0) {
        self.placeHolderView.hidden = YES;
        [self.waitingView stopAnimating];
    } else {
        self.placeHolderView.hidden = NO;
        [self.waitingView startAnimating];
    }
    
    // 获取视频时长 网速慢可能会需要等待 卡住主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimeInterval totalTime = CMTimeGetSeconds(self.asset.duration);
        // 截屏次数
        int captureTimes = (totalTime / 10);
        for (int i = 0; i < captureTimes; i++) {
            UIImage *image = [self thumbImageForVideo:[NSURL URLWithString:playInfo.url] atTime:10 * i];
            if (image) {
                [[self mutableArrayValueForKey:@"thumbImages"] addObject:image];
            }
        }
        // 添加视频最后一帧缩略图到数组
        UIImage *lastImage = [self thumbImageForVideo:[NSURL URLWithString:playInfo.url] atTime:totalTime];
        if (lastImage) {
            [[self mutableArrayValueForKey:@"thumbImages"] addObject:lastImage];
        }
    });
}

// 创建播放器
- (AVPlayer *)setupPlayer
{
    AVPlayer *player = [[AVPlayer alloc] init];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
    return player;
}

// 重置播放器
- (void)resetPlayer
{
    [self removePlayItemObserverAndNotification];
    [self removeTimeObserver];
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.asset = nil;
    self.playerItem = nil;
    self.player = nil;
    self.imageGenerator = nil;
    self.placeHolderView.image = nil;
}

// 添加亮度和音量调节View
- (void)setupBrightnessAndVolumeView
{
    YGBrightnessAndVolumeView *brightnessAndVolumeView = [YGBrightnessAndVolumeView sharedBrightnessAndAudioView];
    brightnessAndVolumeView.progressChangeHandle = ^(CGFloat delta) {
        [self gestureDragProgress:delta];
    };
    brightnessAndVolumeView.progressPortraitEnd = ^{
        [self gestureDragEnd];
    };
    brightnessAndVolumeView.progressLandscapeEnd = ^{
        [self progressDragEnd:self.progressSlider];
    };
    [self addSubview:brightnessAndVolumeView];
    self.brightnessAndVolumeView = brightnessAndVolumeView;
}

// 给playItem添加观察者KVO
- (void)addPlayItemObserverAndNotification
{
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:NULL];
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeStatusBarStyle:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

// 移除观察者和通知
- (void)removePlayItemObserverAndNotification
{
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player removeObserver:self forKeyPath:@"rate"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 给进度条Slider添加时间OB
- (void)addTimerObserver
{
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        weakSelf.currentTimeLabel.text = [NSString stringWithTime:CMTimeGetSeconds(weakSelf.player.currentTime)];
        weakSelf.progressSlider.value = CMTimeGetSeconds(weakSelf.player.currentTime);
    }];
}

// 移除时间OB
- (void)removeTimeObserver
{
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

// KVO监测到播放完调用
- (void)playFinished:(NSNotification *)note {
    UIView *cover = [[UIView alloc] init];
    [self addSubview:cover];
    cover.backgroundColor = [UIColor blackColor];
    cover.alpha = 0.7;
    self.cover = cover;
    
    UIButton *replayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cover addSubview:replayBtn];
    [replayBtn setImage:[UIImage imageNamed:@"replay"] forState:UIControlStateNormal];
    replayBtn.titleLabel.font = [UIFont systemFontOfSize:24];
    [replayBtn setTitle:@"重播" forState:UIControlStateNormal];
    [replayBtn setTitleColor:[UIColor colorWithRed:190/255.0 green:190/255.0 blue:190/255.0 alpha:1.0] forState:UIControlStateNormal];
    replayBtn.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    replayBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 15);
    [replayBtn addTarget:self action:@selector(replay) forControlEvents:UIControlEventTouchUpInside];
    self.replayBtn = replayBtn;
    self.playerItem = [note object];
    [self removeGestureRecognizer:self.tapGesture];
}

// 播放完后重播
- (void)replay
{
    [self.cover removeFromSuperview];
    [self hideControlPanel];
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
    [self addGesture];
}

// KVO检测播放器各种状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    AVPlayerItem *playItem = (AVPlayerItem *)object;
    NSTimeInterval totalTime = CMTimeGetSeconds(self.asset.duration);
    if ([keyPath isEqualToString:@"status"]) { // 检测播放器状态
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) { // 达到能播放的状态
            self.totalTimeLabel.text = [NSString stringWithTime:totalTime];
            self.placeHolderView.hidden = YES;
            self.placeHolderView.image = nil;
            self.progressSlider.maximumValue = totalTime;
            [self playOrPauseAction];
        } else if (status == AVPlayerStatusFailed) { // 播放错误 资源不存在 网络问题等等
            [self.waitingView stopAnimating];
            UILabel *busyLabel = [[UILabel alloc] init];
            busyLabel.font = [UIFont systemFontOfSize:13];
            busyLabel.textColor = [UIColor whiteColor];
            busyLabel.backgroundColor = [UIColor clearColor];
            busyLabel.textAlignment = NSTextAlignmentCenter;
            busyLabel.text = @"资源不存在...";
            [self addSubview:busyLabel];
            [busyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.width.equalTo(self);
                make.height.mas_equalTo(30);
            }];
        } else if (status == AVPlayerStatusUnknown) { // 未知错误
            [self.waitingView stopAnimating];
            UILabel *errorLabel = [[UILabel alloc] init];
            errorLabel.font = [UIFont systemFontOfSize:13];
            errorLabel.textColor = [UIColor whiteColor];
            errorLabel.backgroundColor = [UIColor clearColor];
            errorLabel.textAlignment = NSTextAlignmentCenter;
            errorLabel.text = @"网络错误，请检查手机网络...";
            [self addSubview:errorLabel];
            [errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.center.width.equalTo(self);
                make.height.mas_equalTo(30);
            }];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) { // 检测缓存状态
        NSArray *loadedTimeRanges = [playItem loadedTimeRanges];
        CMTimeRange timeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
        NSTimeInterval bufferingTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalTime = CMTimeGetSeconds(playItem.duration);
        [self.loadedView setProgress:bufferingTime / totalTime animated:YES];
        if (bufferingTime > CMTimeGetSeconds(playItem.currentTime) + 5.f) {
            [self.waitingView stopAnimating];
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {  // 缓存为空
        if (playItem.playbackBufferEmpty) {
            [self.waitingView startAnimating];
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) { // 缓存足够能播放
        if (playItem.playbackLikelyToKeepUp) {
            [self.waitingView stopAnimating];
        }
    } else if ([keyPath isEqualToString:@"thumbImages"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            int imageIndex = (int)self.progressSlider.value / 10;
            if (imageIndex < self.thumbImages.count) {
                self.previewView.image = self.thumbImages[imageIndex];
            }
        });
    } else if ([keyPath isEqualToString:@"rate"]) {
        AVPlayer *player = (AVPlayer *)object;
        if (player.reasonForWaitingToPlay == AVPlayerWaitingWhileEvaluatingBufferingRateReason) {
            [self.waitingView startAnimating];
            [self showOrHideControlPanel];
        }
    }
}

// 横竖屏适配
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) { // 转至竖屏
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(20));
            make.left.equalTo(@(0));
            make.width.equalTo(@(scrnW));
            make.height.equalTo(@(scrnW * 9 / 16));
        }];
        self.episodeBtn.hidden = YES;
        [self.rotateBtn setImage:[UIImage imageNamed:@"player_fullScreen_iphone"] forState:UIControlStateNormal];
        self.topViewHeightConstraint.constant = 40;
        self.rotateBtnLeadingConstraint.constant = 5;
        self.landscape = NO;
    } else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) { // 转至横屏
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.right.bottom.left.equalTo(@(0));
        }];
        self.episodeBtn.hidden = NO;
        [self.rotateBtn setImage:[UIImage imageNamed:@"player_window_iphone"] forState:UIControlStateNormal];
        self.topViewHeightConstraint.constant = 60;
        self.rotateBtnLeadingConstraint.constant = 50;
        self.landscape = YES;
    }
}

// 播放或暂停按钮点击
- (IBAction)playOrPauseAction
{
    [self playOrPause];
}

// 中间大的播放或站厅按钮点击
- (IBAction)centerPlayOrPauseAction
{
    [self playOrPause];
}

// 点击按钮旋转屏幕
- (IBAction)rotateScreen:(UIButton *)sender
{
    if (self.isLandscape) { // 转至竖屏
        [self setForceDeviceOrientation:UIDeviceOrientationPortrait];
    } else { // 转至横屏
        [self setForceDeviceOrientation:UIDeviceOrientationLandscapeLeft];
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }
}

// 拖拽进度条
- (IBAction)dragProgressAction:(UISlider *)sender {

    self.endedDrag = NO;
    [self.player pause];
    [self removeTimeObserver];
    self.currentTimeLabel.text = [NSString stringWithTime:sender.value];
    int imageIndex = sender.value / 10;
    self.previewView.alpha = 1.f;
    self.previewView.title = [NSString stringWithTime:sender.value];
    
    NSTimeInterval totalTime = CMTimeGetSeconds(self.asset.duration);
    [self.previewView.progressView setProgress:(sender.value / totalTime)  animated:YES];
    if (imageIndex < self.thumbImages.count) {
        self.previewView.image = self.thumbImages[imageIndex];
    } else {
        self.previewView.image = nil;
    }
}

// 横向手势拖拽时显示进度条或者缩略图
- (void)gestureDragProgress:(CGFloat)delta
{
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentTime);
    currentTime = currentTime + delta;
    self.progressSlider.value = currentTime;
    [self dragProgressAction:self.progressSlider];
}

// 进度条拖拽结束
- (void)progressDragEnd:(UISlider *)sender
{
    self.endedDrag = YES;
    
    [UIView animateWithDuration:.5f animations:^{
        self.previewView.alpha = .0f;
    }];
    [self.player seekToTime:CMTimeMake(self.progressSlider.value, 1.0)];
    [self addTimerObserver];
    [self.player play];
    // 延迟10.0秒后隐藏播放控制面板
    [self performSelector:@selector(autoFadeOutControlPanelAndStatusBar) withObject:nil afterDelay:10.f];
}

// // 横向手势拖拽手势结束
- (void)gestureDragEnd
{
    [UIView animateWithDuration:.5f animations:^{
        self.previewView.alpha = .0f;
    }];
}

// 获取AVURLAsset的任意一帧图片
- (UIImage *)thumbImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    [self.imageGenerator cancelAllCGImageGeneration];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    self.imageGenerator.maximumSize = CGSizeMake(160, 90);
    
    CGImageRef thumbImageRef = NULL;
    NSError *thumbImageGenerationError = nil;
    thumbImageRef = [self.imageGenerator copyCGImageAtTime:CMTimeMake(time, 1) actualTime:NULL error:&thumbImageGenerationError];
//    NSLog(@"%@", thumbImageGenerationError);
    UIImage *thumbImage = [[UIImage alloc] initWithCGImage:thumbImageRef];
    // 用完要释放 不然会存在内存泄漏
    CGImageRelease(thumbImageRef);
    if (thumbImageRef) {
        return thumbImage;
    } else {
        return nil;
    }
}

// 点击选集按钮
- (IBAction)selectEpisodeAction:(UIButton *)sender {
    UIButton *episodeCover = [UIButton buttonWithType:UIButtonTypeCustom];
    episodeCover.backgroundColor = [UIColor blackColor];
    episodeCover.alpha = 0.8f;
    [episodeCover addTarget:self action:@selector(removeEpisodeCover:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:episodeCover];
    self.episodeCover = episodeCover;
    [episodeCover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.left.top.bottom.equalTo(self);
    }];
    
    UITableView *episodeTableView = [[UITableView alloc] init];
    episodeTableView.backgroundColor = [UIColor clearColor];
    episodeTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    episodeTableView.separatorColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:.4f];
    episodeTableView.dataSource = self;
    episodeTableView.delegate = self;
    [self.episodeCover addSubview:episodeTableView];
    episodeTableView.frame = CGRectMake(0, 0, scrnW * 0.7, scrnH - 100);
    episodeTableView.center = self.center;
    [self removeGestureRecognizer:self.tapGesture];
}

// 移除选集遮盖
- (void)removeEpisodeCover:(UIButton *)episodeCover
{
    [episodeCover removeFromSuperview];
    [self addGesture];
}

#pragma mark - UITableView DataSource 实现数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.playInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"episode";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    YGPlayInfo *playInfo = self.playInfos[indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentPlayingUrl = [defaults objectForKey:@"currentPlayingUrl"];
    if ([currentPlayingUrl isEqualToString:playInfo.url]) {
        cell.textLabel.textColor = [UIColor orangeColor];
    } else {
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", playInfo.artist, playInfo.title];
    return cell;
}

#pragma mark - UITableView Delegate 实现代理方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    YGPlayInfo *playInfo = self.playInfos[indexPath.row];
    [self removeEpisodeCover:self.episodeCover];
    [self playWithPlayInfo:playInfo];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

// 强制切换屏幕方向
- (void)setForceDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:deviceOrientation] forKey:@"orientation"];
}

// 播放或暂停
- (void)playOrPause
{
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
        [self.player play];
        [self.playBtn setImage:[UIImage imageNamed:@"Stop"] forState:UIControlStateNormal];
        [self.centerPlayBtn setImage:[UIImage imageNamed:@"player_pause_iphone_fullscreen"] forState:UIControlStateNormal];
    } else if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        [self.player pause];
        [self.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [self.centerPlayBtn setImage:[UIImage imageNamed:@"player_start_iphone_fullscreen"] forState:UIControlStateNormal];
    }
}

// 添加手势识别器
- (void)addGesture
{
    // 添加Tap手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideControlPanel)];
    [self addGestureRecognizer:tapGesture];
    self.tapGesture = tapGesture;
}

// 显示或隐藏播放器控制面板
- (void)showOrHideControlPanel
{
    if (self.controlPanelIsShowing && !self.isEndedDrag) {
        [self hideControlPanel];
        if (self.isLandscape) {
            [self hideStatusBar];
        }
    } else if (!self.controlPanelIsShowing && self.isEndedDrag){
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [UIView animateWithDuration:.5f animations:^{
            [self showControlPanel];
            [self showStatusBar];
        }];
        [self performSelector:@selector(autoFadeOutControlPanelAndStatusBar) withObject:nil afterDelay:10.f];
    }
}

// 显示播放控制面板
- (void)showControlPanel
{
    self.controlPanelShow = YES;
    self.topViewTopConstraint.constant = 0;
    self.topView.alpha = 1.f;
    self.bottomViewBottomConstaint.constant = 0;
    self.bottomView.alpha = 1.f;
}

// 隐藏播放控制面板
- (void)hideControlPanel
{
    self.controlPanelShow = NO;
    self.topViewTopConstraint.constant = -self.topView.bounds.size.height;
    self.topView.alpha = .0f;
    self.bottomViewBottomConstaint.constant = -self.bottomView.bounds.size.height;
    self.bottomView.alpha = .0f;
}

// 自动淡出播放控制面板
- (void)autoFadeOutControlPanelAndStatusBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self hideControlPanel];
    if (!self.isLandscape) return;
    [self hideStatusBar];
}

// 显示状态栏
- (void)showStatusBar
{
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    statusBar.alpha = 1.f;
}

// 隐藏状态栏
- (void)hideStatusBar
{
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    statusBar.alpha = .0f;
}

// 根据方向改变状态栏的风格
- (void)changeStatusBarStyle:(NSNotification *)note
{
    UIInterfaceOrientation statusOrientation = [note.userInfo[@"UIApplicationStatusBarOrientationUserInfoKey"] integerValue];
    if (statusOrientation == UIInterfaceOrientationPortrait) {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    } else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    }
}

- (void)dealloc
{
    [self removePlayItemObserverAndNotification];
    [self removeTimeObserver];
    [self removeObserver:self forKeyPath:@"thumbImages"];
}
@end
