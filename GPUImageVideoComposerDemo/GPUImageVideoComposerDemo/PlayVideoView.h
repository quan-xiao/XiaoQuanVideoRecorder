//
//  PlayVideoView.h
//  GPUImageVideoComposerDemo
//
//  Created by shengquanjian on 16/3/24.
//  Copyright © 2016年 xq.ios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayVideoView : UIView
@property(nonatomic)AVPlayer * player;
@property(nonatomic,readonly)AVPlayerLayer * playerLayer;
@end
