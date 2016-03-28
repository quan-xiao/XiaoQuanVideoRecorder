//
//  LyricsModel.h
//  GPUImage
//
//  Created by shengquanjian on 15/8/19.
//  Copyright (c) 2015年 shengquanjian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LyricsItem : NSObject

@property(nonatomic,strong)NSString *start;
@property(nonatomic,strong)NSString *end;
@property(nonatomic,strong)NSString *words;

@end

@interface LyricsModel : NSObject
@property (nonatomic,strong)NSMutableArray *lyricsTimeList;//time List
@property (nonatomic,strong)NSMutableDictionary *lyricsDic;//lyricsDict, key:time value:lyric text
@property (nonatomic,strong)NSMutableArray *composeLyricsList;//LyricsItemList

+ (NSString*)getLyricsFromFileContent:(NSString*)path;

-(id)initWithLyricsString:(NSString*)lyrics;

@end
