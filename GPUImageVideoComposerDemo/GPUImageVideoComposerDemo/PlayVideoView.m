//
//  PlayVideoView.m
//  GPUImageVideoComposerDemo
//
//  Created by shengquanjian on 16/3/24.
//  Copyright © 2016年 xq.ios. All rights reserved.
//

#import "PlayVideoView.h"
@implementation PlayVideoView

+(Class)layerClass{
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
- (AVPlayerLayer *)playerLayer{
    return (AVPlayerLayer *)self.layer;
}
@end