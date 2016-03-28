//
//  RecorderLyricLabel.m
//  GPUImageVideoComposerDemo
//
//  Created by shengquanjian on 16/3/24.
//  Copyright © 2016年 xq.ios. All rights reserved.
//

#import "RecorderLyricLabel.h"

#define BOTTOM_MARGIN   10

@implementation RecorderLyricLabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

-(void)customInit
{
    self.backgroundColor=[UIColor clearColor];
    self.textAlignment=NSTextAlignmentCenter;
    self.textColor=[UIColor whiteColor];
    self.font=[UIFont boldSystemFontOfSize:30];
    self.layer.shadowColor=[[UIColor blackColor] CGColor];
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0.45;
    self.layer.shadowOffset = CGSizeMake(-7.5*cos(-120*M_PI/180), 7.5*sin(-120*M_PI/180));
}
@end
