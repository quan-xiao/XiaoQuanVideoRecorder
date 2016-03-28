//
//  ViewController.m
//  GPUImageVideoComposerDemo
//
//  Created by shengquanjian on 16/3/24.
//  Copyright © 2016年 xq.ios. All rights reserved.
//

#import "ViewController.h"
#import "XiaoQuanGPUImageVideorRecorder.h"
#import "PreviewViewController.h"
#import "RecorderLyricLabel.h"

#define VIEW_WIDTH   MIN([UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)
#define VIEW_HEIGHT  MAX([UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)
#define IMAGE_DISPLAY_SIZE(x)   (CGSizeMake(x.size.width*x.scale/MAX(1.0,[UIScreen mainScreen].scale),x.size.height*x.scale/MAX(1.0,[UIScreen mainScreen].scale)))

@interface ViewController ()<XiaoQuanGPUImageVideorRecorderDelegate>
{
}
@property (nonatomic,strong) XiaoQuanGPUImageVideorRecorder* videoRecorder;
@property (strong, nonatomic) UIView *viewContainer;
@property (strong, nonatomic) UIButton *takeButton;
@property (nonatomic,strong) LyricsModel *lyricsModel;
@property (nonatomic,assign) NSUInteger secondsToWait;
@property (nonatomic,weak) NSTimer* tickTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self buildRecorder];
    [self buildViewComponent];
    [self bulidTakeButton];
    [self parserLyrics];
    [self recorderReady];
}

-(void)dealloc
{
    _videoRecorder.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)buildRecorder
{
    _videoRecorder = [[XiaoQuanGPUImageVideorRecorder alloc] init];
    _videoRecorder.delegate = self;
}

-(void)bulidTakeButton
{
    self.takeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.takeButton.backgroundColor = [UIColor redColor];
    CGFloat width = 75;
    self.takeButton.frame = CGRectMake((VIEW_WIDTH-width)/2 ,
                                       self.view.frame.size.height-75,
                                       width,
                                       width);
    [self.takeButton setTitle:@"Record" forState:UIControlStateNormal];
    [self.takeButton addTarget:self action:@selector(takeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takeButton];
}

-(BOOL)detectCameraPermissions
{
    BOOL ret=NO;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        ret=YES;
    } else if(authStatus == AVAuthorizationStatusDenied||authStatus == AVAuthorizationStatusRestricted){
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        }];
    } else {
        // impossible, unknown authorization status
    }
    return ret;
}

-(NSString*)tempVideoPath
{
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *name = [NSString stringWithFormat:@"tmp-%lld.mov",(long long)time];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    return path;
}

-(void)enableTakeButton:(BOOL)enable
{
    [_takeButton setEnabled:enable];
    [_takeButton setTitle:enable?@"Record":@"wait 28s" forState:UIControlStateNormal];
    if (enable&&[self.tickTimer isValid]) {
        [self.tickTimer invalidate];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_videoRecorder resumeCapture];
    [self enableTakeButton:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_videoRecorder pauseCapture];
}

- (void)takeButtonClick:(UIButton *)sender
{
    if (![self detectCameraPermissions]) {
        return;
    }
    _videoRecorder.exportURL= [NSURL fileURLWithPath:[self tempVideoPath]];
    [_videoRecorder prepareForRecording];
    [self enableTakeButton:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(startRecordVideo) withObject:nil afterDelay:1];
}

-(void)finishRecordVideo
{
    [_videoRecorder finishRecording];
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}

-(void)updateTimer:(NSTimer*)timer
{
    _secondsToWait--;
    if (_secondsToWait<=0) {
        [timer invalidate];
    }
    else
    {
        [self.takeButton setTitle:[NSString stringWithFormat:@"wait %ds",_secondsToWait] forState:UIControlStateNormal];
    }
}

-(void)startRecordVideo
{
    if(![UIApplication sharedApplication].idleTimerDisabled)
    {
        [UIApplication sharedApplication].idleTimerDisabled=YES;
    }
    [_videoRecorder startRecording];
    _secondsToWait=28;
    self.tickTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(finishRecordVideo) withObject:nil afterDelay:28];
}

-(NSString*)getCurrntSoundFilePath
{
    return [[NSBundle mainBundle] pathForResource:@"go" ofType:@"mp3"];
}

-(void)parserLyrics
{
    NSString *soundPath= [self getCurrntSoundFilePath];
    NSString *lyrics = nil;
    lyrics = [LyricsModel getLyricsFromFileContent:soundPath];
    self.lyricsModel = [[LyricsModel alloc] initWithLyricsString:lyrics];
}

-(void)recorderReady
{
    UIView* uiElementView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 480, 480)];
    uiElementView.backgroundColor=[UIColor clearColor];
    //add water mark
    UIImage* waterMaskImage=[UIImage imageNamed:@"water_mask"];
    UIImageView*  waterMaskImageView=[[UIImageView alloc] initWithImage:waterMaskImage];
    CGRect frame=waterMaskImageView.frame;
    CGSize imgSize=IMAGE_DISPLAY_SIZE(waterMaskImage);
    CGFloat screenWidth=MAX(VIEW_WIDTH, 320);
    frame.size=CGSizeMake(imgSize.width*480/screenWidth, imgSize.height*480/screenWidth);
    frame.origin= CGPointMake(8.0/screenWidth*480, 8.0/screenWidth*480);
    waterMaskImageView.frame=frame;
    [uiElementView addSubview:waterMaskImageView];
    
    RecorderLyricLabel* lyricLabel=[[RecorderLyricLabel alloc] initWithFrame:CGRectMake(0, uiElementView.bounds.size.height-70, uiElementView.bounds.size.width, 70-15)];
    [uiElementView addSubview:lyricLabel];
    
    _videoRecorder.uiElementView=uiElementView;
    _videoRecorder.lyricsLabel=lyricLabel;
    _videoRecorder.lyricsModel=self.lyricsModel;
    _videoRecorder.audioPath=[[NSBundle mainBundle] pathForResource:@"go" ofType:@"mp3"];
    _videoRecorder.cropVideoRect=CGRectMake(0, 80.0/640, 1, 480.0/640);
    [_videoRecorder startCapture];
}

-(void)showPreviewPage:(NSURL*)videoURL
{
    PreviewViewController* previewVC=[[PreviewViewController alloc]init];
    previewVC.videoURL=videoURL;
    [self.navigationController pushViewController:previewVC animated:YES];
}

- (void)buildViewComponent
{
    self.viewContainer = _videoRecorder.cameraView;
    self.viewContainer.backgroundColor=[UIColor clearColor];
    self.viewContainer.frame=CGRectMake(0, 0, VIEW_WIDTH, VIEW_WIDTH);
    [self.view addSubview:self.viewContainer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)stopRecordVideo
{
    if ([_videoRecorder isInRecording]) {
        [_videoRecorder cancelRecording];
    }
    [UIApplication sharedApplication].idleTimerDisabled=NO;
    [self enableTakeButton:YES];
}

#pragma mark - KaShowGPUImageVideorRecorderDelegate
-(void)XiaoQuanGPUImageVideorRecorderDidStartRecording:(XiaoQuanGPUImageVideorRecorder*)videoRecord
{
    
}

-(void)XiaoQuanGPUImageVideorRecorderDidFinishRecording:(XiaoQuanGPUImageVideorRecorder*)videoRecord error:(NSError*)error
{
    NSURL* exportURL=[videoRecord exportURL];
    if (error) {
        if (exportURL) {
            [[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
        }
        return;
    }
    [self showPreviewPage:exportURL];
    [self stopRecordVideo];
}
#pragma mark
-(void)didBecomeActive:(NSNotification*)obj
{
    NSLog(@"did active!");
    [self.videoRecorder appDidBecomeActive];
}

-(void)didResignActive:(NSNotification*)obj
{
    NSLog(@"did enter background!");
    [self.videoRecorder appWillResignActive];
    [self stopRecordVideo];
}
@end
