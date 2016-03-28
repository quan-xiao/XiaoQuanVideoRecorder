//
//  GPUImageMovieCustomAudioWriter.h
//  GPUImage
//
//  Created by shengquanjian on 15/9/2.
//  Copyright (c) 2015年 shengquanjian. All rights reserved.
//

#import <GPUImage4iOS/GPUImage4iOS.h>

@interface GPUImageMovieCustomAudioWriter : GPUImageMovieWriter

@property (nonatomic,strong) NSURL* audioURL;
@property (nonatomic,assign) BOOL audioInputMuted;//whether microphone is disabled
@property (nonatomic,weak) dispatch_queue_t audioProcessingQueue;

-(BOOL)isInRecording;

@end
