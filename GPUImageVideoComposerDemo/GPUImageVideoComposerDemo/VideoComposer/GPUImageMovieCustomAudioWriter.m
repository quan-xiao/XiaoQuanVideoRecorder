//
//  GPUImageMovieCustomAudioWriter.m
//  GPUImage
//
//  Created by shengquanjian on 15/9/2.
//  Copyright (c) 2015年 shengquanjian. All rights reserved.
//

#import "GPUImageMovieCustomAudioWriter.h"

@interface GPUImageMovieCustomAudioWriter()
@property (nonatomic,strong) AVAssetReaderAudioMixOutput* audioTrackOuput;
@property (nonatomic,strong) AVAssetReader* audioReader;
@property (nonatomic,strong) AVAsset* audioAsset;
@property (nonatomic,assign) BOOL audioEnded;
@property (nonatomic,assign) CMSampleBufferRef lastSampleBuffer;
@property (nonatomic,assign) CMItemCount lastSampleBufferStart;
@property (nonatomic,assign) CMTime beginTime;
@end

@implementation GPUImageMovieCustomAudioWriter

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings
{
    self=[super initWithMovieURL:newMovieURL size:newSize fileType:newFileType outputSettings:outputSettings];
    if(self)
    {
        
    }
    return self;
}

-(void)startRecording
{
    self.audioEnded=NO;
    [self initAudio];
    [super startRecording];
}

-(void)setAudioURL:(NSURL *)audioURL
{
    _audioURL=audioURL;
    self.audioAsset=[[AVURLAsset alloc] initWithURL:self.audioURL options:nil];
}

-(void)initAudio
{
    NSError* error=nil;
    NSArray* tracks=nil;
    
    if (self.audioAsset==nil||((tracks=[self.audioAsset tracksWithMediaType:AVMediaTypeAudio]).count)==0) {
        self.audioEnded=YES;
        self.beginTime=kCMTimeZero;
        self.audioReader=nil;
        self.audioTrackOuput=nil;
        return;
    }
    AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:self.audioAsset error:&error];
    AVAssetReaderAudioMixOutput* readerOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:tracks audioSettings:nil];
    [reader addOutput:readerOutput];
    if(self.audioReader)
    {
        [self.audioReader cancelReading];
    }
    self.audioReader=reader;
    self.audioTrackOuput=readerOutput;
    [self.audioReader startReading];
    self.beginTime=kCMTimeInvalid;
    assetWriterAudioInput.expectsMediaDataInRealTime=!self.audioInputMuted;
}

- (CMSampleBufferRef)adjustSample:(CMSampleBufferRef) sample original:(CMSampleBufferRef)original
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(original, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(original, count, pInfo, &count);
    
    CMItemCount count2;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count2);
    
    CMSampleBufferRef sout=NULL;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, MIN(count,count2), pInfo, &sout);
    free(pInfo);
    return sout;
}

- (CMSampleBufferRef)adjustSample:(CMSampleBufferRef) sample offsetTime:(CMTime)offsetTime
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    CMTime tmp;
    for (CMItemCount i=0; i<count; i++) {
        tmp=pInfo[i].decodeTimeStamp;
        pInfo[i].decodeTimeStamp=CMTimeAdd(tmp, offsetTime);
        tmp=pInfo[i].presentationTimeStamp;
        pInfo[i].presentationTimeStamp=CMTimeAdd(tmp, offsetTime);
    }
    CMSampleBufferRef sout=NULL;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

-(void)finalProcessAudioBuffer:(CMSampleBufferRef)audioBuffer original:(CMSampleBufferRef)original
{
    CMSampleBufferRef newBuffer=NULL;
    newBuffer=[self adjustSample:audioBuffer original:original];
    if (newBuffer) {
        [super processAudioBuffer:newBuffer];
        CFRelease(newBuffer);
    }
}

-(void)processAudioBuffer:(CMSampleBufferRef)audioBuffer
{
    if (![self isInRecording]) {
        return;
    }
    if (self.audioEnded) {
        return;
    }
    CMItemCount sampleCount=CMSampleBufferGetNumSamples(audioBuffer);
    CMSampleBufferRef sample = NULL;
    CMItemCount sampleStart=0;
    if (self.lastSampleBuffer) {
        sample=self.lastSampleBuffer;
        sampleStart=self.lastSampleBufferStart;
    }
    else
    {
       sample=[self.audioTrackOuput copyNextSampleBuffer];
    }
    while (sample) {
        CMItemCount tmpCount=CMSampleBufferGetNumSamples(sample);
        BOOL hasLast=self.lastSampleBuffer!=NULL;
        if (hasLast) {
            tmpCount-=self.lastSampleBufferStart;
        }
        sampleCount-=tmpCount;
        if (sampleCount>=0) {
            if (sampleStart>0) {
                CMSampleBufferRef newBuffer=NULL;
                CMSampleBufferCopySampleBufferForRange(NULL,sample,CFRangeMake(sampleStart,tmpCount),&newBuffer);
                CFRelease(sample);
                sample=newBuffer;
            }
            if (!sample) {
                break;
            }
            [self finalProcessAudioBuffer:sample original:audioBuffer];
            CFRelease(sample);
            if (hasLast) {
                self.lastSampleBuffer=NULL;
                self.lastSampleBufferStart=0;
            }
            if (sampleCount==0) {
                break;
            }
            sample = [self.audioTrackOuput copyNextSampleBuffer];
            sampleStart = 0;
            continue;
        }
        else
        {
            CMSampleBufferRef newBuffer=NULL;
            CMSampleBufferCopySampleBufferForRange(NULL,sample,CFRangeMake(sampleStart, tmpCount+sampleCount),&newBuffer);
            if (!newBuffer) {
                CFRelease(sample);
                break;
            }
            [self finalProcessAudioBuffer:newBuffer original:audioBuffer];
            CFRelease(newBuffer);
            if (self.lastSampleBuffer!=sample) {
                CFRetain(sample);
                if (self.lastSampleBuffer) {
                    CFRelease(self.lastSampleBuffer);
                }
                self.lastSampleBuffer=sample;
                CFRelease(sample);
            }
            self.lastSampleBufferStart=sampleStart+tmpCount+sampleCount;
            break;
        }
    }
    self.audioEnded=sample==NULL;
}

-(void)releaseSampleBuffer
{
    if (!self.audioInputMuted) {
        dispatch_queue_t q=self.audioProcessingQueue;
        if (!q) {
            q=dispatch_get_main_queue();
        }
        dispatch_async(q, ^{
            if (self.lastSampleBuffer) {
                CFRelease(self.lastSampleBuffer);
                self.lastSampleBuffer=NULL;
                self.lastSampleBufferStart=0;
            }
            self.audioEnded=YES;
        });
    }
}

-(void)cancelRecording
{
    [super cancelRecording];
    [self releaseSampleBuffer];
}

-(void)finishRecordingWithCompletionHandler:(void (^)(void))handler
{
    [super finishRecordingWithCompletionHandler:handler];
    [self releaseSampleBuffer];
}

-(void)myProcessAudioBuffer:(CMSampleBufferRef)audioBuffer
{
    CMTime currentSampleTime =CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
    CFRetain(audioBuffer);
    void(^write)() = ^() {
        while (!assetWriterAudioInput.readyForMoreMediaData&&[self isInRecording])
        {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
            //NSLog(@"audio waiting...");
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        if ([self isInRecording]) {
            if (!assetWriterAudioInput.readyForMoreMediaData)
            {
                NSLog(@"2: Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }
            else if(assetWriter.status == AVAssetWriterStatusWriting)
            {
                if (![assetWriterAudioInput appendSampleBuffer:audioBuffer])
                    NSLog(@"Problem appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }
            else
            {
            }
        }
        if (self.shouldInvalidateAudioSampleWhenDone)
        {
            CMSampleBufferInvalidate(audioBuffer);
        }
        CFRelease(audioBuffer);
    };
    if( self.encodingLiveVideo )
    {
        runSynchronouslyOnContextQueue(_movieWriterContext, write);
    }
    else
    {
        write();
    }
}

-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    //test if it is the first frame, take this time as the begin time
    if (_audioInputMuted&&CMTIME_IS_INVALID(self.beginTime)&&self.isInRecording)
    {
        if(CMTIME_IS_VALID([[self valueForKey:@"startTime"] CMTimeValue]))
        {
            self.beginTime=frameTime;
            __weak __typeof(self) weakSelf=self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100*NSEC_PER_MSEC),
                           self.audioProcessingQueue,
                           ^{
                [weakSelf manuallyAppendAudio:nil];
            });
        }
    }
}

-(void)manuallyAppendAudio:(void(^)())block
{
    __weak __typeof(self) weakSelf=self;
    dispatch_queue_t q=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    if (assetWriter.status!=AVAssetWriterStatusWriting) {
        return;
    }
    [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:q usingBlock:^{
        __typeof(self) strongSelf=weakSelf;
        if (!strongSelf) {
            return;
        }
        while ([strongSelf->assetWriterAudioInput isReadyForMoreMediaData])
        {
//            if (![strongSelf->assetWriterAudioInput isReadyForMoreMediaData]) {
//                break;
//            }
            CMSampleBufferRef nextSampleBuffer = [weakSelf.audioTrackOuput copyNextSampleBuffer];
            if (nextSampleBuffer)
            {
                CMSampleBufferRef tmpBuffer=NULL;
                tmpBuffer=[strongSelf adjustSample:nextSampleBuffer offsetTime:weakSelf.beginTime];
                CFRelease(nextSampleBuffer);
                if (!tmpBuffer) {
                    break;
                }
                [strongSelf myProcessAudioBuffer:tmpBuffer];
                CFRelease(tmpBuffer);
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    runAsynchronouslyOnContextQueue(weakSelf.movieWriterContext,^()
                                                   {
                                                       if (strongSelf->assetWriter.status==AVAssetWriterStatusWriting&&![[strongSelf valueForKey:@"audioEncodingIsFinished"] boolValue]) {
                                                           [strongSelf setValue:@(YES) forKey:@"audioEncodingIsFinished"];
                                                           [strongSelf->assetWriterAudioInput markAsFinished];
                                                       }
                                                       if (block) {
                                                           block();
                                                       }
                                                   });
                });
                
            }
        }
    }];
}

-(BOOL)isInRecording
{
    return [[self valueForKey:@"isRecording"] boolValue];
}
@end
