//
//  PlayViewModel.m
//  DanWanPlayer
//
//  Created by JimHuang on 15/12/24.
//  Copyright © 2015年 JimHuang. All rights reserved.
//

#import "PlayViewModel.h"
#import "DanMuModel.h"
#import "DanMuNetManager.h"
#import "LocalVideoModel.h"
#import "JHVLCMedia.h"
#import "VLCMedia+Tools.h"
@interface PlayViewModel()
@property (strong, nonatomic) NSArray <LocalVideoModel *>*videos;
@property (strong, nonatomic) NSMutableDictionary <NSNumber *,VLCMedia *>*VLCMedias;
@end

@implementation PlayViewModel
- (NSString *)localeVideoNameWithIndex:(NSInteger)index{
    return [self localVideoModelWithIndex: index].fileName;
}

- (NSInteger)localeVideoCount{
    return self.videos.count;
}

- (NSString *)currentVideoName{
    return [self videoNameWithIndex: self.currentIndex];
}

- (LocalVideoModel *)currentLocalVideoModel{
    return [self localVideoModelWithIndex: self.currentIndex];
}

- (void)setCurrentIndex:(NSInteger)currentIndex{
    _currentIndex = currentIndex>0?currentIndex%self.videos.count:0;
}

- (void)currentVLCMediaWithCompletionHandler:(void(^)(VLCMedia *responseObj))complete{
    [self VLCMediaWithIndex:self.currentIndex completionHandler:complete];
}
- (NSArray <DanMuDataModel *>*)currentSecondDanMuArr:(NSInteger)second{
    return self.dic[@(second)];
}



#pragma mark - 私有方法
- (NSURL *)videoURLWithIndex:(NSInteger)index{
    return [self localVideoModelWithIndex: index].filePath?[self localVideoModelWithIndex: index].filePath:nil;
}

- (NSString *)videoNameWithIndex:(NSInteger)index{
    return [self localVideoModelWithIndex: index].fileName?[self localVideoModelWithIndex: index].fileName:@"";
}

- (void)VLCMediaWithIndex:(NSInteger)index completionHandler:(void(^)(VLCMedia *responseObj))complete{
    if (!self.VLCMedias[@(index)]) {
        self.VLCMedias[@(index)] = [VLCMedia mediaWithURL: [self videoURLWithIndex: index]];
    }
    
    if (self.VLCMedias[@(index)].isParsed) {
        complete(self.VLCMedias[@(index)]);
        return;
    }
    
    [[[JHVLCMedia alloc] initWithURL: [self videoURLWithIndex: index]] parseWithBlock:^(VLCMedia *aMedia) {
        complete(aMedia);
        self.VLCMedias[@(index)] = aMedia;
    }];
}

- (LocalVideoModel *)localVideoModelWithIndex:(NSInteger)index{
    return index<self.videos.count?self.videos[index]:nil;
}

- (instancetype)initWithLocalVideoModels:(NSArray *)localVideoModels danMuDic:(NSDictionary *)dic{
    if (self = [super init]) {
        self.videos = localVideoModels;
        self.testarr = [NSMutableArray array];
        [localVideoModels enumerateObjectsUsingBlock:^(LocalVideoModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.testarr addObject:[VLCMedia mediaWithURL:[obj filePath]]];
        }];
        self.dic = [dic mutableCopy];
    }
    return self;
}

#pragma mark - 懒加载

- (NSMutableDictionary <NSNumber *,VLCMedia *> *)VLCMedias {
	if(_VLCMedias == nil) {
		_VLCMedias = [[NSMutableDictionary <NSNumber *,VLCMedia *> alloc] init];
	}
	return _VLCMedias;
}

@end
