//
//  XiaoQuanGPUImageVideorRecorder.h
//  GPUImage
//
//  Created by shengquanjian on 15/9/1.
//  Copyright (c) 2015年 shengquanjian. All rights reserved.
//
//  A video recorder based on GPUImage capable of cut, audio composition, lyric composition, watermark and etc.

#import "LyricsModel.h"
#import <GPUImage4iOS/GPUImage4iOS.h>

@class XiaoQuanGPUImageVideorRecorder;
@protocol XiaoQuanGPUImageVideorRecorderDelegate <NSObject>
@optional
-(void)XiaoQuanGPUImageVideorRecorderDidStartRecording:(XiaoQuanGPUImageVideorRecorder*)videoRecord;
-(void)XiaoQuanGPUImageVideorRecorderDidFinishRecording:(XiaoQuanGPUImageVideorRecorder*)videoRecord error:(NSError*)error;
@end

@interface XiaoQuanGPUImageVideorRecorder : NSObject

@property (nonatomic,readonly) UIView* cameraView;
@property (nonatomic,copy) NSURL* exportURL;
@property (nonatomic,copy) NSString* audioPath;//the file path of the audio file
@property (nonatomic,strong) LyricsModel* lyricsModel;
@property (nonatomic,assign) CGRect cropVideoRect;//x,y both range from 0 to 1
@property (nonatomic,strong) UIView* uiElementView; //custom container view for showing lyric ,watermark and etc
@property (nonatomic,strong) UILabel* lyricsLabel; //the lable used for showing lyric
@property (nonatomic,weak) id<XiaoQuanGPUImageVideorRecorderDelegate> delegate;
@property(nonatomic, copy) void(^uiElementViewUpdateCallback)(UIView* container, UIView* lyricsLabel, CMTime time);

-(void)startCapture;
-(void)pauseCapture;
-(void)stopCapture;
-(void)resumeCapture;
-(void)startRecording;
-(void)finishRecording;
-(void)cancelRecording;
-(void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
-(void)changeCameraPosition;
-(BOOL)checkIfAudioMuted;
-(BOOL)isInRecording;
//when app resigns active, should call this method to do some cleaning
-(void)appWillResignActive;
//when app becomes active, should calll this method to restore states
-(void)appDidBecomeActive;
//should call this method before recording as early as possible, as it's a little time-consuming
- (BOOL)prepareForRecording;
@end
