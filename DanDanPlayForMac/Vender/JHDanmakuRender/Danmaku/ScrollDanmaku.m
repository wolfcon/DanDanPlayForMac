//
//  ScrollDanmaku.m
//  JHDanmakuRenderDemo
//
//  Created by JimHuang on 16/2/22.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "ScrollDanmaku.h"
#import "DanmakuContainer.h"

@interface ScrollDanmaku()
@property (assign, nonatomic) CGFloat speed;
@property (assign, nonatomic) scrollDanmakuDirection direction;
@end

@implementation ScrollDanmaku

- (instancetype)initWithFontSize:(CGFloat)fontSize textColor:(NSColor *)textColor text:(NSString *)text shadowStyle:(danmakuShadowStyle)shadowStyle font:(NSFont *)font speed:(CGFloat)speed direction:(scrollDanmakuDirection)direction{
    if (self = [super initWithFontSize:fontSize textColor:textColor text:text shadowStyle:shadowStyle font:font]) {
        _speed = speed;
        _direction = direction;
    }
    return self;
}

- (BOOL)updatePositonWithTime:(NSTimeInterval)time container:(DanmakuContainer *)container{
    CGRect windowsFrame = NSApp.keyWindow.frame;
    CGRect containerFrame = container.frame;
    CGPoint point = container.originalPosition;
    switch (_direction) {
        case scrollDanmakuDirectionR2L:
        {
            point.x -= _speed * (time - self.appearTime);
            containerFrame.origin = point;
            container.frame = containerFrame;
            return containerFrame.origin.x + containerFrame.size.width >= 0;
        }
        case scrollDanmakuDirectionL2R:
        {
            point.x += _speed * (time - self.appearTime);
            containerFrame.origin = point;
            container.frame = containerFrame;
            return containerFrame.origin.x <= windowsFrame.size.width;
        }
        case scrollDanmakuDirectionT2B:
        {
            point.y -= _speed * (time - self.appearTime);
            containerFrame.origin = point;
            container.frame = containerFrame;
            return containerFrame.origin.y + containerFrame.size.height >= 0;
        }
        case scrollDanmakuDirectionB2T:
            point.y += _speed * (time - self.appearTime);
            containerFrame.origin = point;
            container.frame = containerFrame;
            return containerFrame.origin.y <= windowsFrame.size.height;
    }
    return NO;
}

/**
 *  遍历所有同方向的弹幕
 如果方向是左右或者右左 channelHeight = 窗口高/channelCount
 如果是上下或者下上 channelHeight = 窗口宽/channelCount
 左右方向按照y/channelHeight 归类
 上下方向按照x/channelHeight 归类
 优先选择没有弹幕的轨道
 如果都有 选出每条轨道上跑地最慢的弹幕 再从这些弹幕中选出跑地最远的弹幕 它所在的轨道就是所选轨道
 */
- (CGPoint)originalPositonWithContainerArr:(NSArray <DanmakuContainer *>*)arr channelCount:(NSInteger)channelCount contentRect:(CGRect)rect danmakuSize:(CGSize)danmakuSize timeDifference:(NSTimeInterval)timeDifference{
    NSMutableDictionary <NSNumber *, NSMutableArray <DanmakuContainer *>*>*dic = [NSMutableDictionary dictionary];
    channelCount = (channelCount == 0) ? [self channelCountWithContentRect:rect danmakuSize:danmakuSize] : channelCount;
    //轨道高
    NSInteger channelHeight = [self channelHeightWithChannelCount:channelCount contentRect:rect];
    for (int i = 0; i < arr.count; ++i) {
        DanmakuContainer *obj = arr[i];
        if ([obj.danmaku isKindOfClass:[ScrollDanmaku class]] && [(ScrollDanmaku *)obj.danmaku direction] == _direction) {
            //判断弹幕所在轨道
            NSInteger channel = [self channelWithFrame:obj.frame channelHeight:channelHeight];
            
            if (!dic[@(channel)]) dic[@(channel)] = [NSMutableArray array];
            
            //选出距离最小者
            DanmakuContainer *firstContainer = dic[@(channel)].firstObject;
            if (firstContainer && [self isMinDistanceDanmakuWithFirstObjFrame:firstContainer.frame selfFrame:obj.frame]) {
                [dic[@(channel)] insertObject:obj atIndex:0];
            }else{
                [dic[@(channel)] addObject:obj];
            }
        }
    }
    
    __block NSInteger channel = channelCount - 1;
    if (dic.count == channelCount) {
        __block CGRect maxDistance = dic[@(0)].firstObject.frame;
        __block BOOL firstGreatEqualThanSecond;
        //选出距离最大者
        [dic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSMutableArray <DanmakuContainer *>* _Nonnull obj, BOOL * _Nonnull stop) {
            maxDistance = [self maxDistanceWithFirstObjFrame:obj.firstObject.frame secondObjFrame:maxDistance firstGreaterEqualThanSecond:&firstGreatEqualThanSecond];
            if (firstGreatEqualThanSecond) channel = key.intValue;
        }];
    }else{
        for (NSInteger i = channelCount - 1; i >= 0; --i) {
            if (!dic[@(i)]) {
                channel = i;
                break;
            }
        }
    }
    
    switch (_direction) {
        case scrollDanmakuDirectionR2L:
            return CGPointMake(rect.size.width - timeDifference * _speed, channelHeight * channel);
        case scrollDanmakuDirectionL2R:
            return CGPointMake(-danmakuSize.width + timeDifference * _speed, channelHeight * channel);
        case scrollDanmakuDirectionB2T:
            return CGPointMake(channelHeight * channel, -danmakuSize.height + timeDifference * _speed);
        case scrollDanmakuDirectionT2B:
            return CGPointMake(channelHeight * channel, rect.size.height - timeDifference * _speed);
    }
    return CGPointMake(rect.size.width, rect.size.height);
}

- (CGFloat)speed{
    return _speed;
}

- (scrollDanmakuDirection)direction{
    return _direction;
}


#pragma mark - 私有方法
- (NSInteger)channelCountWithContentRect:(CGRect)contentRect danmakuSize:(CGSize)danmakuSize{
    NSInteger channelCount = 0;
    if (_direction == scrollDanmakuDirectionL2R || _direction == scrollDanmakuDirectionR2L) {
        channelCount = contentRect.size.height / danmakuSize.height;
        return channelCount > 4 ? channelCount : 4;
    }
    channelCount = contentRect.size.width / danmakuSize.width;
    return channelCount > 4 ? channelCount : 4;
}

- (NSInteger)channelHeightWithChannelCount:(NSInteger)channelCount contentRect:(CGRect)rect{
    if (_direction == scrollDanmakuDirectionL2R || _direction == scrollDanmakuDirectionR2L) {
        return rect.size.height / channelCount;
    }else{
        return rect.size.width / channelCount;
    }
}

- (NSInteger)channelWithFrame:(CGRect)frame channelHeight:(CGFloat)channelHeight{
    if (_direction == scrollDanmakuDirectionL2R || _direction == scrollDanmakuDirectionR2L) {
        return frame.origin.y / channelHeight;
    }else{
        return frame.origin.x / channelHeight;
    }
}

- (BOOL)isMinDistanceDanmakuWithFirstObjFrame:(CGRect)firstObjFrame selfFrame:(CGRect)selfFrame{
    switch (_direction) {
        case scrollDanmakuDirectionB2T:
            return selfFrame.origin.y < firstObjFrame.origin.y;
        case scrollDanmakuDirectionT2B:
            return selfFrame.origin.y > firstObjFrame.origin.y;
        case scrollDanmakuDirectionL2R:
            return selfFrame.origin.x < firstObjFrame.origin.x;
        case scrollDanmakuDirectionR2L:
            return selfFrame.origin.x > firstObjFrame.origin.x;
    }
    return NO;
}

- (CGRect)maxDistanceWithFirstObjFrame:(CGRect)firstObjFrame secondObjFrame:(CGRect)secondObjFrame firstGreaterEqualThanSecond:(BOOL *)firstGreaterEqualThanSecond{
    switch (_direction) {
        case scrollDanmakuDirectionB2T:
            if (firstObjFrame.origin.y >= secondObjFrame.origin.y) {
                *firstGreaterEqualThanSecond = YES;
                return firstObjFrame;
            }else{
                *firstGreaterEqualThanSecond = NO;
                return secondObjFrame;
            }
        case scrollDanmakuDirectionT2B:
            if (firstObjFrame.origin.y <= secondObjFrame.origin.y) {
                *firstGreaterEqualThanSecond = YES;
                return firstObjFrame;
            }else{
                *firstGreaterEqualThanSecond = NO;
                return secondObjFrame;
            }
        case scrollDanmakuDirectionL2R:
            if (firstObjFrame.origin.x >= secondObjFrame.origin.x) {
                *firstGreaterEqualThanSecond = YES;
                return firstObjFrame;
            }else{
                *firstGreaterEqualThanSecond = NO;
                return secondObjFrame;
            }
        case scrollDanmakuDirectionR2L:
            if (firstObjFrame.origin.x <= secondObjFrame.origin.x) {
                *firstGreaterEqualThanSecond = YES;
                return firstObjFrame;
            }else{
                *firstGreaterEqualThanSecond = NO;
                return secondObjFrame;
            }
    }
    *firstGreaterEqualThanSecond = NO;
    return CGRectZero;
}

@end