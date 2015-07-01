//
//  PooPlayMovieViewController.m
//  MoviePlayer
//
//  Created by crazypoo on 14-4-22.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooPlayMovieViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>
#import "MBProgressHUD.h"

#define TopViewHeight     44
#define BottomViewHeight  72
#define VolumeStep        0.02f
#define BrightnessStep    0.02f
#define MovieProgressStep 5.0f
#define INTERFACE_IS_PAD [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#define INTERFACE_IS_PHONE   ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define screenWidth ([UIScreen mainScreen].bounds.size.width)
#define screenHeight ([UIScreen mainScreen].bounds.size.height)

#define IOS7 ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)

typedef NS_ENUM(NSInteger, GestureType){
    GestureTypeOfNone = 0,
    GestureTypeOfVolume,
    GestureTypeOfBrightness,
    GestureTypeOfProgress,
};

//TODO:記住播放進度相關的數據庫操作類
@interface DatabaseManager : NSObject
+ (id)defaultDatabaseManager;
- (void)addPlayRecordWithIdentifier:(NSString *)identifier progress:(CGFloat)progress;
- (CGFloat)getProgressByIdentifier:(NSString *)identifier;
@end

@interface PooPlayMovieViewController ()

@property (nonatomic,assign) BOOL           isPlaying;
@property (nonatomic,strong) AVPlayer       *player;
@property (nonatomic,strong) NSMutableArray *itemTimeList;
@property (nonatomic       ) CGFloat        movieLength;
@property (nonatomic       ) NSInteger      currentPlayingItem;
@property (nonatomic,strong) MBProgressHUD  *progressHUD;
@property (nonatomic,strong) UIView         *topView;
@property (nonatomic,strong) UIButton       *returnBtn;
@property (nonatomic,strong) UILabel        *titleLable;
@property (nonatomic,strong) UIView         *bottomView;
@property (nonatomic,strong) UIButton       *playBtn;
@property (nonatomic,strong) UIButton       *backwardBtn;
@property (nonatomic,strong) UIButton       *forwardBtn;
@property (nonatomic,strong) UIButton       *fastBackwardBtn;
@property (nonatomic,strong) UIButton       *fastForeardBtn;
@property (nonatomic,strong) UISlider       *movieProgressSlider;
@property (nonatomic,strong) UILabel        *currentLable;
@property (nonatomic,strong) UILabel        *remainingTimeLable;
@property (nonatomic,strong) UIImageView    *brightnessView;
@property (nonatomic,strong) UIProgressView *brightnessProgress;
@property (nonatomic,strong) UIView         *progressTimeView;
@property (nonatomic,strong) UILabel        *progressTimeLable_top;
@property (nonatomic,strong) UILabel        *progressTimeLable_bottom;
@property (nonatomic,assign) CGFloat        ProgressBeginToMove;
@property (nonatomic,weak  ) id             timeObserver;
@property (nonatomic,assign) GestureType    gestureType;
@property (nonatomic,assign) CGPoint        originalLocation;
@property (nonatomic,assign) CGFloat        systemBrightness;
//TODO: 第一次打開需要讀取歷史進度
@property (nonatomic,assign) BOOL           isFirstOpenPlayer;
@end

@implementation PooPlayMovieViewController

- (void)viewWillDisappear:(BOOL)animated{
    if(_player.currentItem && _player){
        [_player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - init
- (id)initNetworkPooPlayMovieViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle
{
    self = [super init];
    if (self)
    {
        _isPlaying         = YES;
        _isFirstOpenPlayer = NO;
        _movieURL          = url;
        _movieURLList      = @[url];
        _movieTitle        = movieTitle;
        _itemTimeList      = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = PooPlayMovieViewControllerModeNetwork;
    }
    return self;
}

- (id)initLocalPooPlayMovieViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle
{
    self = [super init];
    if (self)
    {
        _isPlaying         = YES;
        _isFirstOpenPlayer = NO;
        _movieURL          = url;
        _movieURLList      = @[url];
        _movieTitle        = movieTitle;
        _itemTimeList      = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = PooPlayMovieViewControllerModeLocal;
    }
    return self;
}

- (id)initLocalPooPlayMovieViewControllerWithURLList:(NSArray *)urlList movieTitle:(NSString *)movieTitle
{
    self = [super init];
    if (self)
    {
        _isPlaying         = YES;
        _isFirstOpenPlayer = NO;
        _movieURL          = nil;
        _movieURLList      = urlList;
        _movieTitle        = movieTitle;
        _itemTimeList      = [[NSMutableArray alloc]initWithCapacity:5];
        _mode = PooPlayMovieViewControllerModeLocal;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        //TODO:ios7
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    self.view.backgroundColor = [UIColor blackColor];
    [self createTopView];
    [self createBottomView];
    [self createAvPlayer];
    [self createBrightnessView];
    [self createProgressTimeLable];
    [self performSelector:@selector(hidenControlBar) withObject:nil afterDelay:3];
    [self.view bringSubviewToFront:_topView];
    [self.view bringSubviewToFront:_bottomView];
    //TODO: 監控活動狀態，打電話時/鎖屏就停止播放
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    //TODO: 引導頁面
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"firstStart"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstStart"];
        //TODO: 引導頁面
        UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, screenHeight, screenWidth)];
        btn.contentMode = UIViewContentModeScaleAspectFill;
        if (self.view.frame.size.height>500)
        {
            [btn setImage:[UIImage imageNamed:@"video_tips@2x.png"] forState:UIControlStateNormal];
        }
        else
        {
            [btn setImage:[UIImage imageNamed:@"video_tips@2x.png"] forState:UIControlStateNormal];
        }
        [btn addTarget:self action:@selector(firstCoverOnClick:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:btn];
    }
    else
    {
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    _systemBrightness = [UIScreen mainScreen].brightness;
}

- (void)createAvPlayer
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];

    CGRect playerFrame           = CGRectMake(0, 0, self.view.layer.bounds.size.height, self.view.layer.bounds.size.width);

    __block CMTime totalTime     = CMTimeMake(0, 0);
    [_movieURLList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSURL *url                   = (NSURL *)obj;
        AVPlayerItem *playerItem     = [AVPlayerItem playerItemWithURL:url];
        totalTime.value              += playerItem.asset.duration.value;
        totalTime.timescale          = playerItem.asset.duration.timescale;
        [_itemTimeList addObject:[NSNumber numberWithDouble:((double)playerItem.asset.duration.value/totalTime.timescale)]];
    }];
    _movieLength               = (CGFloat)totalTime.value/totalTime.timescale;
    _player                    = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[0]]];

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame          = playerFrame;
    playerLayer.videoGravity   = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    [_player play];
    _currentPlayingItem = 0;
    
    //TODO: 檢測加載狀態的通知
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //TODO: 避免內存洩露
    __weak typeof(_player) player_                           = _player;
    __weak typeof(_movieProgressSlider) movieProgressSlider_ = _movieProgressSlider;
    __weak typeof(_currentLable) currentLable_               = _currentLable;
    __weak typeof(_remainingTimeLable) remainingTimeLable_   = _remainingTimeLable;
    __weak typeof(_itemTimeList) itemTimeList_               = _itemTimeList;
    typeof(_movieLength) *movieLength_                       = &_movieLength;
    typeof(_gestureType) *gestureType_                       = &_gestureType;
    typeof(_currentPlayingItem) *currentPlayingItem_         = &_currentPlayingItem;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(3, 30) queue:NULL usingBlock:^(CMTime time){
        if ((*gestureType_) != GestureTypeOfProgress) {
            //TODO:拿時間
            CMTime currentTime     = player_.currentItem.currentTime;
            double currentPlayTime = (double)currentTime.value/currentTime.timescale;

            NSInteger currentTemp  = *currentPlayingItem_;
            
            while (currentTemp > 0) {
                currentPlayTime += [(NSNumber *)itemTimeList_[currentTemp-1] doubleValue];
                --currentTemp;
            }
            //TODO:換成秒
            CGFloat remainingTime      = (*movieLength_) - currentPlayTime;
            movieProgressSlider_.value = currentPlayTime/(*movieLength_);
            NSDate *currentDate        = [NSDate dateWithTimeIntervalSince1970:currentPlayTime];
            NSDate *remainingDate      = [NSDate dateWithTimeIntervalSince1970:remainingTime];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

            [formatter setDateFormat:(currentPlayTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
            NSString *currentTimeStr   = [formatter stringFromDate:currentDate];
            [formatter setDateFormat:(remainingTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
            NSString *remainingTimeStr = [NSString stringWithFormat:@"-%@",[formatter stringFromDate:remainingDate]];

            currentLable_.text         = currentTimeStr;
            remainingTimeLable_.text   = remainingTimeStr;
        }
    }];
    
    _progressHUD = [[MBProgressHUD alloc]initWithView:self.view];
    [self.view addSubview:_progressHUD];
    [_progressHUD show:YES];
}

- (void)createTopView
{
    CGFloat titleLableWidth = 400;
    _topView                    = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, TopViewHeight)];
    _topView.backgroundColor    = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];

    _returnBtn                  = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, TopViewHeight)];
    [_returnBtn setTitle:@"返回" forState:UIControlStateNormal];
    [_returnBtn setTitleColor:[UIColor colorWithRed:0.01f green:0.48f blue:0.98f alpha:1.00f] forState:UIControlStateNormal];
    [_returnBtn addTarget:self action:@selector(popView) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:_returnBtn];

    _titleLable                 = [[UILabel alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2-titleLableWidth/2, 0, titleLableWidth, TopViewHeight)];
    _titleLable.backgroundColor = [UIColor clearColor];
    _titleLable.text            = _movieTitle;
    _titleLable.textColor       = [UIColor whiteColor];
    _titleLable.textAlignment   = NSTextAlignmentCenter;
    [_topView addSubview:_titleLable];

    [self.view addSubview:_topView];
}

- (void)createBottomView
{
    CGRect bounds               = self.view.bounds;
    _bottomView                 = [[UIView alloc]initWithFrame:CGRectMake(0, bounds.size.width-BottomViewHeight, bounds.size.height, BottomViewHeight)];
    _bottomView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.4f];

    CGFloat marginTop           = 13;
    _playBtn                    = [[UIButton alloc]initWithFrame:CGRectMake(bounds.size.height/2-20, marginTop-12, 40, 40)];
    [_playBtn setImage:[UIImage imageNamed:@"pause_nor.png"] forState:UIControlStateNormal];
    [_playBtn addTarget:self action:@selector(pauseBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_playBtn];

    _fastBackwardBtn            = [[UIButton alloc]initWithFrame:CGRectMake(_playBtn.frame.origin.x-56-21, marginTop, 21, 16)];
    _fastBackwardBtn.tag        = 1;
    [_fastBackwardBtn setImage:[UIImage imageNamed:@"fast_backward_nor.png"] forState:UIControlStateNormal];
    [_fastBackwardBtn addTarget:self action:@selector(fastAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_fastBackwardBtn];

    _fastForeardBtn             = [[UIButton alloc]initWithFrame:CGRectMake(_playBtn.frame.origin.x+_playBtn.frame.size.width+56, marginTop, 21, 16)];
    _fastForeardBtn.tag         = 2;
    [_fastForeardBtn setImage:[UIImage imageNamed:@"fast_forward_nor.png"] forState:UIControlStateNormal];
    [_fastForeardBtn addTarget:self action:@selector(fastAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_fastForeardBtn];

    _forwardBtn                 = [[UIButton alloc]initWithFrame:CGRectMake(_fastForeardBtn.frame.origin.x+_fastForeardBtn.frame.size.width+56, marginTop, 16, 16)];
    _forwardBtn.tag             = 1;
    [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateNormal];
    [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateHighlighted
     ];
    [_bottomView addSubview:_forwardBtn];

    _backwardBtn                = [[UIButton alloc]initWithFrame:CGRectMake(_fastBackwardBtn.frame.origin.x-56-16, marginTop, 16, 16)];
    _backwardBtn.tag            = 2;
    [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateNormal];
    [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateHighlighted];
    [_bottomView addSubview:_backwardBtn];
    
    if (_datasource)
    {
        if ([_datasource isHaveNextMovie])
        {
            [_forwardBtn setImage:[UIImage imageNamed:@"forward_nor.png"] forState:UIControlStateNormal];
            [_forwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([_datasource isHavePreviousMovie])
        {
            [_backwardBtn setImage:[UIImage imageNamed:@"backward_nor.png"] forState:UIControlStateNormal];
            [_backwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    CGFloat bottomOrigin_y              = BottomViewHeight - 30;
    _currentLable                       = [[UILabel alloc]initWithFrame:CGRectMake(0 , bottomOrigin_y, 63, 20)];
    _currentLable.font                  = [UIFont systemFontOfSize:13];
    _currentLable.textColor             = [UIColor whiteColor];
    _currentLable.backgroundColor       = [UIColor clearColor];
    _currentLable.textAlignment         = NSTextAlignmentCenter;
    [_bottomView addSubview:_currentLable];

    _movieProgressSlider                = [[UISlider alloc]initWithFrame:CGRectMake(63, bottomOrigin_y, bounds.size.height-126, 20)];
    [_movieProgressSlider setMinimumTrackTintColor:[UIColor whiteColor]];
    [_movieProgressSlider setMaximumTrackTintColor:[UIColor colorWithRed:0.49f green:0.48f blue:0.49f alpha:1.00f]];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb.png"] forState:UIControlStateNormal];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    [_bottomView addSubview:_movieProgressSlider];

    _remainingTimeLable                 = [[UILabel alloc]initWithFrame:CGRectMake(bounds.size.height-63, bottomOrigin_y, 63, 20)];
    _remainingTimeLable.font            = [UIFont systemFontOfSize:13];
    _remainingTimeLable.textColor       = [UIColor whiteColor];
    _remainingTimeLable.backgroundColor = [UIColor clearColor];
    _remainingTimeLable.textAlignment   = NSTextAlignmentCenter;
    [_bottomView addSubview:_remainingTimeLable];

    [self.view addSubview:_bottomView];
}

- (void)createBrightnessView
{
    _brightnessView                   = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2-63, self.view.frame.size.width/2-63, 125, 125)];
    _brightnessView.image             = [UIImage imageNamed:@"video_brightness_bg.png"];

    _brightnessProgress               = [[UIProgressView alloc]initWithFrame:CGRectMake(_brightnessView.frame.size.width/2-40, _brightnessView.frame.size.height-30, 80, 10)];
    _brightnessProgress.trackImage    = [UIImage imageNamed:@"video_num_bg.png"];
    _brightnessProgress.progressImage = [UIImage imageNamed:@"video_num_front.png"];
    _brightnessProgress.progress      = [UIScreen mainScreen].brightness;
    [_brightnessView addSubview:_brightnessProgress];
    [self.view addSubview:_brightnessView];
    _brightnessView.alpha             = 0;
}

- (void)createProgressTimeLable
{
    _progressTimeView                         = [[UIView alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2-100, self.view.bounds.size.width/2-30, 200, 60)];
    _progressTimeLable_top                    = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 200, 30)];
    _progressTimeLable_top.textAlignment      = NSTextAlignmentCenter;
    _progressTimeLable_top.textColor          = [UIColor whiteColor];
    _progressTimeLable_top.backgroundColor    = [UIColor clearColor];
    _progressTimeLable_top.font               = [UIFont systemFontOfSize:25];
    _progressTimeLable_top.shadowColor        = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    _progressTimeLable_top.shadowOffset       = CGSizeMake(1.0, 1.0);
    [_progressTimeView addSubview:_progressTimeLable_top];

    _progressTimeLable_bottom                 = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, 200, 30)];
    _progressTimeLable_bottom.textAlignment   = NSTextAlignmentCenter;
    _progressTimeLable_bottom.textColor       = [UIColor whiteColor];
    _progressTimeLable_bottom.backgroundColor = [UIColor clearColor];
    _progressTimeLable_bottom.font            = [UIFont systemFontOfSize:25];
    _progressTimeLable_bottom.shadowColor     = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    _progressTimeLable_bottom.shadowOffset    = CGSizeMake(1.0, 1.0);
    [_progressTimeView addSubview:_progressTimeLable_bottom];

    [self.view addSubview:_progressTimeView];
}

- (void)updateProfressTimeLable
{
    double currentTime             = floor(_movieLength *_movieProgressSlider.value);
    double changeTime              = floor(_movieLength*ABS(_movieProgressSlider.value-_ProgressBeginToMove));
    //TODO:換成秒
    NSDate *currentDate            = [NSDate dateWithTimeIntervalSince1970:currentTime];
    NSDate *changeDate             = [NSDate dateWithTimeIntervalSince1970:changeTime];
    NSDateFormatter *formatter     = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    [formatter setDateFormat:(currentTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
    NSString *currentTimeStr       = [formatter stringFromDate:currentDate];

    [formatter setDateFormat:(changeTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
    NSString *changeTimeStr        = [formatter stringFromDate:changeDate];

    _progressTimeLable_top.text    = currentTimeStr;
    _progressTimeLable_bottom.text = [NSString stringWithFormat:@"[%@ %@]",(_movieProgressSlider.value-_ProgressBeginToMove) < 0? @"-":@"+",changeTimeStr];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"])
    {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        
        if (playerItem.status == AVPlayerStatusReadyToPlay)
        {
            [_progressHUD hide:YES];
            //TODO: 獲取上次博商進度，僅對本地播放有效
            if (!_isFirstOpenPlayer)
            {
                CGFloat progress = [[DatabaseManager defaultDatabaseManager] getProgressByIdentifier:_movieTitle];
                _movieProgressSlider.value = progress;
                _isFirstOpenPlayer = YES;
                [self scrubbingDidEnd];
            }
        }
    }
    [_player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
//    if ([keyPath isEqualToString:@"loadedTimeRanges"])
//    {
//        float bufferTime = [self availableDuration];
//        NSLog(@"缓冲进度%f",bufferTime);
//        float durationTime = CMTimeGetSeconds([[_player currentItem] duration]);
//        NSLog(@"缓冲进度：%f , 百分比：%f",bufferTime,bufferTime/durationTime);
//    }
}
//TODO: 加載進度
//- (float)availableDuration
//{
//    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
//    if ([loadedTimeRanges count] > 0) {
//        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
//        float startSeconds = CMTimeGetSeconds(timeRange.start);
//        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
//        return (startSeconds + durationSeconds);
//    }else{
//        return 0.0f;
//    }
//}

#pragma mark - action
- (void)becomeActive
{
    [self pauseBtnClick];
}

- (void)resignActive
{
    [self pauseBtnClick];
}

- (void)pauseBtnClick
{
    _isPlaying = !_isPlaying;
    if (_isPlaying)
    {
        [_player play];
        [_playBtn setImage:[UIImage imageNamed:@"pause_nor.png"] forState:UIControlStateNormal];
        
    }
    else
    {
        [_player pause];
        [_playBtn setImage:[UIImage imageNamed:@"play_nor.png"] forState:UIControlStateNormal];
    }
}

- (void)fastAction:(UIButton *)btn
{
    if (btn.tag == 1)
    {
        [self movieProgressAdd:-MovieProgressStep];
    }else if (btn.tag == 2)
    {
        [self movieProgressAdd:MovieProgressStep];
    }
}

- (void)forWordOrBackWardMovieAction:(UIButton *)btn
{
    _movieProgressSlider.value = 0.f;
    [_progressHUD show:YES];
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    NSDictionary *dic = nil;
    if (btn.tag == 1)
    {
        dic = [_datasource nextMovieURLAndTitleToTheCurrentMovie];
    }
    else if(btn.tag == 2)
    {
        dic = [_datasource previousMovieURLAndTitleToTheCurrentMovie];
    }
    _movieURL = (NSURL *)[dic objectForKey:KURLOfMovieDicTionary];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:_movieURL];
    [_player replaceCurrentItemWithPlayerItem:playerItem];
    _movieTitle = [dic objectForKey:KTitleOfMovieDictionary];
    _titleLable.text = _movieTitle;
    //TODO: 檢測通知
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    //TODO: 檢測是否有上or下一部電影
    if (_datasource && [_datasource isHaveNextMovie])
    {
        [_forwardBtn setImage:[UIImage imageNamed:@"forward_nor.png"] forState:UIControlStateNormal];
        [_forwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateNormal];
        [_forwardBtn setImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateHighlighted];
        [_forwardBtn removeTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_datasource && [_datasource isHavePreviousMovie])
    {
        [_backwardBtn setImage:[UIImage imageNamed:@"backward_nor.png"] forState:UIControlStateNormal];
        [_backwardBtn addTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateNormal];
        [_backwardBtn setImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateHighlighted];
        [_backwardBtn removeTarget:self action:@selector(forWordOrBackWardMovieAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

//TODO: 播完之後
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if (_currentPlayingItem+1 == _movieURLList.count) {
        [self popView];
        [_player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
    }else{
        ++_currentPlayingItem;
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:_movieURLList[_currentPlayingItem]]];
        if (_isPlaying == YES){
            [_player play];
        }
//        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld context:nil];
    }
}

- (void)volumeAdd:(CGFloat)step
{
    [MPMusicPlayerController applicationMusicPlayer].volume += step;;
}

- (void)brightnessAdd:(CGFloat)step
{
    [UIScreen mainScreen].brightness += step;
    _brightnessProgress.progress = [UIScreen mainScreen].brightness;
}

- (void)movieProgressAdd:(CGFloat)step
{
    _movieProgressSlider.value += (step/_movieLength);
    [self scrubberIsScrolling];
}

- (void)firstCoverOnClick:(UIButton *)button
{
    [button removeFromSuperview];
}

- (void)popView
{
    //TODO: 保存播放進度
    [[DatabaseManager defaultDatabaseManager] addPlayRecordWithIdentifier:_movieTitle progress:_movieProgressSlider.value];
    
    [_player removeTimeObserver:_timeObserver];
    [_player replaceCurrentItemWithPlayerItem:nil];
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        self.timeObserver = nil;
        self.player = nil;
        [UIScreen mainScreen].brightness = _systemBrightness;
        if ([_delegate respondsToSelector:@selector(movieFinished:)])
        {
            [_delegate movieFinished:_movieProgressSlider.value];
        }
    }];
}

-(void)scrubbingDidBegin
{
    _gestureType = GestureTypeOfProgress;
    _ProgressBeginToMove = _movieProgressSlider.value;
    _progressTimeView.hidden = NO;
}

-(void)scrubberIsScrolling
{
    if (_mode == PooPlayMovieViewControllerModeNetwork)
    {
        [_progressHUD show:YES];
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    }
    double currentTime = floor(_movieLength *_movieProgressSlider.value);
    
    int i = 0;
    double temp = [((NSNumber *)_itemTimeList[i]) doubleValue];
    while (currentTime > temp)
    {
        ++i;
        temp += [((NSNumber *)_itemTimeList[i]) doubleValue];
    }
    if (i != _currentPlayingItem)
    {
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[i]]];
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        _currentPlayingItem = i;
    }
    temp -= [((NSNumber *)_itemTimeList[i]) doubleValue];
    
    [self updateProfressTimeLable];
    //TODO: 要轉換成CMTime才能讓播放器來控制播放進度
    CMTime dragedCMTime = CMTimeMake(currentTime-temp, 1);
    [_player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish)
    {
         if (_isPlaying == YES)
         {
             [_player play];
         }
     }];
}

-(void)scrubbingDidEnd
{
    _gestureType             = GestureTypeOfNone;
    _progressTimeView.hidden = YES;
    [self scrubberIsScrolling];
}

#pragma mark touch event
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch          = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self.view];
    CGFloat offset_x        = currentLocation.x - _originalLocation.x;
    CGFloat offset_y        = currentLocation.y - _originalLocation.y;
    if (CGPointEqualToPoint(_originalLocation,CGPointZero))
    {
        _originalLocation = currentLocation;
        return;
    }
    _originalLocation = currentLocation;
    
    CGRect frame = [UIScreen mainScreen].bounds;
    if (_gestureType == GestureTypeOfNone)
    {
        if ((currentLocation.x > frame.size.height*0.8) && (ABS(offset_x) <= ABS(offset_y)))
        {
            _gestureType = GestureTypeOfVolume;
        }
        else if ((currentLocation.x < frame.size.height*0.2) && (ABS(offset_x) <= ABS(offset_y)))
        {
            _gestureType = GestureTypeOfBrightness;
        }
        else if ((ABS(offset_x) > ABS(offset_y)))
        {
            _gestureType = GestureTypeOfProgress;
            _progressTimeView.hidden = NO;
        }
    }
    if ((_gestureType == GestureTypeOfProgress) && (ABS(offset_x) > ABS(offset_y)))
    {
        if (offset_x > 0)
        {
            NSLog(@"快进");
            _movieProgressSlider.value += 0.005;
        }else
        {
            NSLog(@"后退");
            _movieProgressSlider.value -= 0.005;
        }
        [self updateProfressTimeLable];
    }
    else if ((_gestureType == GestureTypeOfVolume) && (currentLocation.x > frame.size.height*0.8) && (ABS(offset_x) <= ABS(offset_y)))
    {
        if (offset_y > 0)
        {
            NSLog(@"音量减");
            [self volumeAdd:-VolumeStep];
        }
        else
        {
            NSLog(@"音量加");
            [self volumeAdd:VolumeStep];
        }
    }
    else if ((_gestureType == GestureTypeOfBrightness) && (currentLocation.x < frame.size.height*0.2) && (ABS(offset_x) <= ABS(offset_y)))
    {
        if (offset_y > 0)
        {
            NSLog(@"变暗");
            _brightnessView.alpha = 1;
            [self brightnessAdd:-BrightnessStep];
        }
        else
        {
            NSLog(@"变光");
            _brightnessView.alpha = 1;
            [self brightnessAdd:BrightnessStep];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _originalLocation    = CGPointZero;
    _ProgressBeginToMove = _movieProgressSlider.value;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point  = [touch locationInView:self.view];
    if (_gestureType == GestureTypeOfNone && !CGRectContainsPoint(_bottomView.frame, point) && !CGRectContainsPoint(_topView.frame, point))
    {
        //TODO:狀態欄動作
        [UIView animateWithDuration:0.25 animations:^{
            CGRect topFrame    = _topView.frame;
            CGRect bottomFrame = _bottomView.frame;
            if (topFrame.origin.y<0)
            {
                topFrame.origin.y    = 0;
                float bF = 0;
                if (INTERFACE_IS_PAD) {
                    bF = screenWidth;
                }
                else
                {
                    if (iPhone6) {
                        bF = screenWidth;
                    }
                    else if (iPhone6P)
                    {
                        bF = screenWidth;
                    }
                    else
                    {
                        bF = screenHeight;
                    }
                }
                bottomFrame.origin.y = bF-BottomViewHeight;

                [self performSelector:@selector(hidenControlBar) withObject:nil afterDelay:3];
            }
            else
            {
                topFrame.origin.y    = -TopViewHeight;
                bottomFrame.origin.y = screenWidth;
            }
            _topView.frame    = topFrame;
            _bottomView.frame = bottomFrame;
        }];
    }
    else if (_gestureType == GestureTypeOfProgress)
    {
        _gestureType             = GestureTypeOfNone;
        _progressTimeView.hidden = YES;
        [self scrubberIsScrolling];
    }
    else
    {
        _gestureType = GestureTypeOfNone;
        _progressTimeView.hidden = YES;
        if (_brightnessView.alpha) {
            [UIView animateWithDuration:1 animations:^{
                _brightnessView.alpha = 0;
            }];
        }
    }
}

- (void)hidenControlBar
{
    [UIView animateWithDuration:0.25 animations:^{
        CGRect topFrame      = _topView.frame;
        CGRect bottomFrame   = _bottomView.frame;
        topFrame.origin.y    = -TopViewHeight;
        bottomFrame.origin.y = self.view.frame.size.width;
        _topView.frame       = topFrame;
        _bottomView.frame    = bottomFrame;
    }];
}

#pragma mark - 系统相关
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
@end

#pragma mark --------播放歷史操作
NSString *const MoviePlayerArchiveKey_identifier = @"identifier";
NSString *const MoviePlayerArchiveKey_date       = @"date";
NSString *const MoviePlayerArchiveKey_progress   = @"progress";
NSInteger const MoviePlayerArchiveKey_MaxCount   = 50;

@implementation DatabaseManager
- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

+ (DatabaseManager *)defaultDatabaseManager
{
    static DatabaseManager *manager = nil;
    if (manager == nil)
    {
        manager = [[DatabaseManager alloc]init];
    }
    return manager;
}

+ (NSString *)pathOfArchiveFile
{
    NSArray *filePath       = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath  = [filePath lastObject];
    NSString *plistFilePath = [documentPath stringByAppendingPathComponent:@"playRecord.plist"];
    return plistFilePath;
}
- (void)addPlayRecordWithIdentifier:(NSString *)identifier progress:(CGFloat)progress
{
    NSMutableArray *recardList = [[NSMutableArray alloc]initWithContentsOfFile:[DatabaseManager pathOfArchiveFile]];
    if (!recardList)
    {
        recardList = [[NSMutableArray alloc]init];
    }
    if (recardList.count==MoviePlayerArchiveKey_MaxCount)
    {
        [recardList removeObjectAtIndex:0];
    }
    
    NSDictionary *dic = @{MoviePlayerArchiveKey_identifier:identifier,MoviePlayerArchiveKey_date:[NSDate date],MoviePlayerArchiveKey_progress:@(progress)};
    [recardList addObject:dic];
    [recardList writeToFile:[DatabaseManager pathOfArchiveFile] atomically:YES];
}

- (CGFloat)getProgressByIdentifier:(NSString *)identifier
{
    NSMutableArray *recardList = [[NSMutableArray alloc]initWithContentsOfFile:[DatabaseManager pathOfArchiveFile]];
    __block CGFloat progress = 0;
    [recardList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dic = obj;
        if ([dic[MoviePlayerArchiveKey_identifier] isEqualToString:identifier])
        {
            progress = [dic[MoviePlayerArchiveKey_progress] floatValue];
            *stop = YES;
        }
    }];
    if (progress > 0.9 || progress < 0.05)
    {
        return 0;
    }
    return progress;
}
@end
