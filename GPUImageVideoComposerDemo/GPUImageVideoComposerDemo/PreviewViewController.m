//
//  PreviewViewController.m
//  GPUImageVideoComposerDemo
//
//  Created by shengquanjian on 16/3/24.
//  Copyright © 2016年 xq.ios. All rights reserved.
//

#import "PreviewViewController.h"
#import "PlayVideoView.h"

@interface PreviewViewController()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVURLAsset* videoAsset;
@property (nonatomic, strong) AVPlayerItem* playerItem;
@end

@implementation PreviewViewController

-(void)loadView
{
    self.view=[[PlayVideoView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self playLocalVideo];
}

-(void)playLocalVideo
{
    NSURL *videoUrl = self.videoURL;
    self.playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
        [(PlayVideoView*)self.view setPlayer:self.player];
    [self.player play];
}

-(void)dealloc
{
    //do cleaning
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoURL.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.videoURL.path error:nil];
    }
}
@end
