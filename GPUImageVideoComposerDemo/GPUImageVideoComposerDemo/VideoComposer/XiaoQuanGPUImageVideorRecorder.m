//
//  XiaoQuanGPUImageVideorRecorder.m
//  GPUImage
//
//  Created by shengquanjian on 15/9/1.
//  Copyright (c) 2015年 shengquanjian. All rights reserved.
//

#import "XiaoQuanGPUImageVideorRecorder.h"
#import "GPUImageMovieCustomAudioWriter.h"
#import "GPUImageVideoCamera+Exposed.h"

#define  ERROR_DOMAIN  @"XiaoQuanGPUImageVideorRecorder"
#define  LYRIC_TIME_DELTA   (0.01)

@interface XiaoQuanGPUImageVideorRecorder() <GPUImageMovieWriterDelegate>
@property (nonatomic,strong) GPUImageVideoCamera* videoCamera;
@property (nonatomic,strong) GPUImageMovieCustomAudioWriter* movieWriter;
@property (nonatomic,strong) GPUImageAlphaBlendFilter* blendFilter;
@property (nonatomic,strong) GPUImageUIElement* uiElement;
@property (nonatomic,strong) GPUImageCropFilter* filter;
@property (nonatomic,assign) NSUInteger currentLyricIndex;
@end

@implementation XiaoQuanGPUImageVideorRecorder

-(id)init
{
    self=[super init];
    if (self) {
        [self customInit];
    }
    return self;
}

-(void)appWillResignActive
{
    if ([self isInRecording]) {
        [self cancelRecording];
    }
    [self pauseCapture];
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

-(void)appDidBecomeActive
{
    [self resumeCapture];
    [self startCapture];
}

- (BOOL)prepareForRecording
{
    [self rebuildFilters:YES];
    if(self.uiElementView)
    {
        self.uiElement=[[GPUImageUIElement alloc] initWithView:self.uiElementView];
        /******************************/
        //clean the last content text
        self.lyricsLabel.text=@"";
        [self.uiElement update];
        /******************************/
        [self.uiElement addTarget:self.blendFilter];
        __weak __typeof(self) weakSelf=self;
        [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            if (weakSelf.isInRecording) {
                [weakSelf updateLyrisText:time];
                if (weakSelf.uiElementViewUpdateCallback) {
                    weakSelf.uiElementViewUpdateCallback(weakSelf.uiElementView,weakSelf.lyricsLabel,time);
                }
            }
            [weakSelf.uiElement update];
        }];
    }
    return YES;
}

-(void)buildCameraWithPosition:(AVCaptureDevicePosition)position
{
    self.videoCamera=[[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:position];
    self.videoCamera.horizontallyMirrorFrontFacingCamera=YES;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
}

-(void)customInit
{
    self.cropVideoRect=CGRectMake(0, 0, 1, 1);
    [self buildCameraWithPosition:AVCaptureDevicePositionFront];
    
    _cameraView=[[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self rebuildFilters:NO];
}

-(void)rebuildFilters:(BOOL)recording
{
    self.filter=[[GPUImageCropFilter alloc] initWithCropRegion:self.cropVideoRect];
    if (!recording) {
        [self.videoCamera removeAllTargets];
        [self.filter removeAllTargets];
        [self.filter addTarget:(GPUImageView*)self.cameraView];
        [self.videoCamera addTarget:self.filter];
    }
    else
    {
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:self.filter];
        GPUImageAlphaBlendFilter* blendFilter=[[GPUImageAlphaBlendFilter alloc] init];
        blendFilter.mix=1.0;
        self.blendFilter=blendFilter;
        GPUImageView* v=(GPUImageView*)self.cameraView;
        [self.filter addTarget:self.blendFilter];
        [self.filter addTarget:v];
        
        self.movieWriter.delegate=nil;
        
        CGSize movieSize = CGSizeMake(480*self.cropVideoRect.size.width, 640.0*self.cropVideoRect.size.height);
        NSNumber *bitRate = @(movieSize.width * movieSize.height * 8);
        NSDictionary *compressionSettings = @{AVVideoAverageBitRateKey:bitRate,
                                              AVVideoMaxKeyFrameIntervalKey:@(3)};
        
        NSDictionary *videoOutputSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                               AVVideoCompressionPropertiesKey : compressionSettings,
                                               AVVideoWidthKey : @(movieSize.width),
                                               AVVideoHeightKey : @(movieSize.height) };
        
        self.movieWriter=[[GPUImageMovieCustomAudioWriter alloc] initWithMovieURL:self.exportURL size:movieSize fileType:AVFileTypeQuickTimeMovie outputSettings:videoOutputSettings];
        self.movieWriter.encodingLiveVideo=YES;
        self.movieWriter.delegate=self;
        self.movieWriter.audioInputMuted=YES;
        self.movieWriter.audioProcessingQueue=[self.videoCamera currentAudioProcessingQueue];
        self.movieWriter.hasAudioTrack=YES;
        [self.blendFilter removeAllTargets];
        [self.blendFilter addTarget:self.movieWriter];
    }
}

-(void)setCropVideoRect:(CGRect)cropVideoRect
{
    _cropVideoRect=cropVideoRect;
    [self.filter setCropRegion:cropVideoRect];
}

-(void)startCapture
{
    [self.videoCamera startCameraCapture];
}

-(void)pauseCapture
{
    [self.videoCamera pauseCameraCapture];
}

-(void)stopCapture
{
    [self.videoCamera stopCameraCapture];
}

-(void)resumeCapture
{
    [self.videoCamera resumeCameraCapture];
}

-(void)updateLyrisText:(CMTime)time
{
    static Float64 beginTime=0;
    Float64 t=CMTimeGetSeconds(time);
    if (self.currentLyricIndex==-1) {
        beginTime=t;
        self.currentLyricIndex=0;
    }
    t-=beginTime;
    NSArray* timeList=self.lyricsModel.lyricsTimeList;
    NSUInteger count=timeList.count;
    id key=nil;
    NSUInteger lastCurrentIndex=self.currentLyricIndex;
    NSUInteger i=lastCurrentIndex;
    Float64 dt=0;
    for (; i<count; i++) {
        key=timeList[i];
        dt=t-[key floatValue];
        if (dt>=-LYRIC_TIME_DELTA) {
            self.currentLyricIndex=i+1;
            if (key) {
                self.lyricsLabel.text=self.lyricsModel.lyricsDic[key];
            }
            break;
        }
    }
}

-(void)startRecording
{
    if (!self.exportURL) {
        [self movieRecordingFailedWithError:[NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:@{@"description":@"export path is not valid"}]];
        return;
    }
    NSURL* audioURL=[NSURL fileURLWithPath:self.audioPath];
    if (!audioURL) {
        [self movieRecordingFailedWithError:[NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:@{@"description":@"audio path is not valid"}]];
        return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.exportURL.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.exportURL.path error:nil];
    }
    self.movieWriter.audioURL=audioURL;
    self.currentLyricIndex=-1;
    
    [self.movieWriter startRecording];
    if ([self.delegate respondsToSelector:@selector(XiaoQuanGPUImageVideorRecorderDidStartRecording:)]) {
        [self.delegate XiaoQuanGPUImageVideorRecorderDidStartRecording:self];
    }
}

-(void)doFinalThings:(void (^)(void))handler
{
    [self releaseSomething];
    if (handler) {
        handler();
    }
}

-(void)releaseSomething
{
    [self rebuildFilters:NO];
    [self.blendFilter removeTarget:self.movieWriter];
    [self.uiElement removeAllTargets];
    self.uiElement=nil;
}

-(void)finishRecording
{
    [self finishRecordingWithCompletionHandler:nil];
}

-(BOOL)checkIfAudioMuted
{
    NSArray* inputs=self.videoCamera.captureSession.inputs;
    for (AVCaptureInput* input in inputs) {
        if ([input isKindOfClass:[AVCaptureDeviceInput class]]) {
            AVCaptureDeviceInput* devInput=(AVCaptureDeviceInput*)input;
            if ([[devInput device] hasMediaType:AVMediaTypeAudio]) {
                return NO;
            }
        }
    }
    return YES;
}

-(void)finishRecordingWithCompletionHandler:(void (^)(void))handler
{
    __weak __typeof(self) weakSelf=self;
    [self.movieWriter finishRecordingWithCompletionHandler:^void(void)
     {
         [weakSelf doFinalThings:handler];
     }];
}

-(void)cancelRecording
{
    [self.movieWriter cancelRecording];
    self.movieWriter.delegate=nil;
    [self releaseSomething];
}

-(void)changeCameraPosition
{
    [self.videoCamera rotateCamera];
}

-(BOOL)isInRecording
{
    return [self.movieWriter isInRecording];
}

#pragma mark GPUImageMovieWriterDelegate
- (void)movieRecordingCompleted
{
    if ([self.delegate respondsToSelector:@selector(XiaoQuanGPUImageVideorRecorderDidFinishRecording:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate XiaoQuanGPUImageVideorRecorderDidFinishRecording:self error:nil];
        });
    }
}

- (void)movieRecordingFailedWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(XiaoQuanGPUImageVideorRecorderDidFinishRecording:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate XiaoQuanGPUImageVideorRecorderDidFinishRecording:self error:error];
        });
    }
}
#pragma mark -
@end
