//
//  LyricsModel.m
//  GPUImage
//
//  Created by shengquanjian on 15/8/19.
//  Copyright (c) 2015年 shengquanjian. All rights reserved.
//

#import "LyricsModel.h"

@interface LyricsModel()
{
    NSMutableArray *_arrayTemp;
}
@property (nonatomic,strong)NSString* lyricsSource;
@end

@implementation LyricsModel


+ (NSString*)getLyricsFromFileContent:(NSString*)path
{
    if (!path) {
        return @"";
    }
    NSString *lyricsHead = @"LYRICSBEGININD00003110LYR";
    NSData *lyricsHeadData = [lyricsHead dataUsingEncoding:NSUTF8StringEncoding];
    NSString *lyrics = nil;
    NSData *data = nil;
    NSError *error;
    data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
    NSRange range = [data rangeOfData:lyricsHeadData options:NSDataSearchBackwards range:NSMakeRange(0,data.length)];
    if (range.length == 0){
        return @"";
    }
    NSData *lyricsLenData = [data subdataWithRange:NSMakeRange(range.location+25, 5)];
    NSInteger lyricsLen = [[NSString alloc] initWithData:lyricsLenData encoding:NSUTF8StringEncoding].integerValue;
    NSData *lyricsData = [data subdataWithRange:NSMakeRange(range.location+30, lyricsLen)];
    lyrics = [[NSString alloc] initWithData:lyricsData encoding:NSUTF8StringEncoding];
    return lyrics;
}

-(id)initWithLyricsString:(NSString*)lyrics
{
    if (self = [super init]) {
        self.lyricsSource = lyrics;
        self.lyricsTimeList = [[NSMutableArray alloc] init];
        self.lyricsDic = [[NSMutableDictionary alloc] init];
        _arrayTemp = [[NSMutableArray alloc] init];
        [self parseLrcSourceData];
    }
    return self;
}

-(NSMutableArray *)composeLyricsList
{
    if (!_composeLyricsList) {
        _composeLyricsList = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i<_lyricsTimeList.count; i++) {
            LyricsItem *item = [[LyricsItem alloc] init];
            item.start = [_lyricsTimeList objectAtIndex:i];
            item.words = [_lyricsDic objectForKey:item.start];
            if (i+1<_lyricsTimeList.count) {
                item.end = [_lyricsTimeList objectAtIndex:i+1];
            }
            [_composeLyricsList addObject:item];
        }
    }
    return _composeLyricsList;
}

#pragma mark Privat Method

-(void) parseLrcSourceData
{
    if (!self.lyricsSource || self.lyricsSource.length <= 0)
    {
        return;
    }
    NSArray * tempArray=[self.lyricsSource componentsSeparatedByString:@"\n"];
    for (NSString *str in tempArray)
    {
        if (str && str.length > 0)
        {
            [_arrayTemp removeAllObjects];
            [self parseLrcLineWithLineText:str];
            [self parseTempArray:_arrayTemp];
        }
    }
    if (self.lyricsTimeList && self.lyricsTimeList.count > 0)
        [self sortAllItem:self.lyricsTimeList];
}
-(void) parseLrcLineWithLineText:(NSString *)sourceLineText
{
    if (!sourceLineText || sourceLineText.length <= 0)
        return;
    NSRange range = [sourceLineText rangeOfString:@"]"];
    if (range.length > 0)
    {
        NSString * time = [sourceLineText substringToIndex:range.location + 1];
       // NSLog(@"time = %@",time);
        NSString * other = [sourceLineText substringFromIndex:range.location + 1];
       // NSLog(@"other = %@",other);
        if (time && time.length > 0)
            [_arrayTemp addObject:time];
        if (other)
            [self parseLrcLineWithLineText:other];
    }else
    {
        [_arrayTemp addObject:sourceLineText];
    }
}

-(NSString *)timeToSecond:(NSString *)formatTime
{
    if (!formatTime || formatTime.length <= 0)
        return nil;
    if ([formatTime rangeOfString:@"["].length <= 0 && [formatTime rangeOfString:@"]"].length <= 0)
        return nil;
    if (formatTime.length<10)
        return nil;
    NSString * minutes = [formatTime substringWithRange:NSMakeRange(1, 2)];
    NSString * second = [formatTime substringWithRange:NSMakeRange(4, 5)];
    float finishSecond = minutes.floatValue * 60 + second.floatValue;
    return [NSString stringWithFormat:@"%f",finishSecond];
}

-(void) parseTempArray:(NSMutableArray *) tempArray
{
    if (!tempArray || tempArray.count <= 0)
        return;
    NSString *value = [tempArray lastObject];
    if (!value || ([value rangeOfString:@"["].length > 0 && [value rangeOfString:@"]"].length > 0))
    {
        [_arrayTemp removeAllObjects];
        return;
    }
    
    for (int i = 0; i < tempArray.count - 1; i++)
    {
        NSString * key = [tempArray objectAtIndex:(NSUInteger)i];
        NSString *secondKey = [self timeToSecond:key];
        if (!secondKey)continue;
        [self.lyricsDic setObject:value forKey:secondKey];
        [self.lyricsTimeList addObject:secondKey];
    }
    [_arrayTemp removeAllObjects];
}

-(void)sortAllItem:(NSMutableArray *)array
{
    if (!array || array.count <= 0)
        return;
    for (int i = 0; i < array.count - 1; i++)
    {
        for (int j = i + 1; j < array.count; j++)
        {
            NSString *firstTime = [array objectAtIndex:i];
            NSString *secondTime = [array objectAtIndex:j];
            BOOL b = firstTime.floatValue > secondTime.floatValue;
            if (b)
            {
                [array replaceObjectAtIndex:(NSUInteger )i withObject:secondTime];
                [array replaceObjectAtIndex:(NSUInteger )j withObject:firstTime];
            }
        }
    }
}

@end

@implementation LyricsItem
@end
