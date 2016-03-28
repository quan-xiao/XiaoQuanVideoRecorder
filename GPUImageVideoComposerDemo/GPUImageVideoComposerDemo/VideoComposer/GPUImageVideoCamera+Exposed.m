//
//  GPUImageVideoCamera+Exposed.m
//  GPUImage
//
//  Created by shengquanjian on 15/9/20.
//  Copyright © 2015年 shengquanjian. All rights reserved.
//

#import "GPUImageVideoCamera+Exposed.h"

@interface GPUImageVideoCamera ()
{
@public
    dispatch_queue_t audioProcessingQueue;
}
@end

@implementation GPUImageVideoCamera (Exposed)

-(dispatch_queue_t)currentAudioProcessingQueue
{
    return audioProcessingQueue;
}
@end
