//
//  OpenStreamVideoViewModel.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/3/5.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "OpenStreamVideoViewModel.h"
#import "DanmakuNetManager.h"
#import "StreamingVideoModel.h"

@interface OpenStreamVideoViewModel()
@property (strong, nonatomic) NSString *aid;
@property (assign, nonatomic) NSUInteger page;
@property (assign, nonatomic) DanDanPlayDanmakuSource danmakuSource;
@end

@implementation OpenStreamVideoViewModel

- (void)getVideoURLAndDanmakuForRow:(NSInteger)row completionHandler:(void(^)(StreamingVideoModel *videoModel, DanDanPlayErrorModel *error))complete {
    VideoInfoDataModel *vm = self.models[row];
    [self getVideoURLAndDanmakuForVideoName:vm.title danmaku:vm.danmaku danmakuSource:self.danmakuSource completionHandler:complete];
}

- (void)getVideoURLAndDanmakuForVideoName:(NSString *)videoName danmaku:(NSString *)danmaku danmakuSource:(DanDanPlayDanmakuSource)danmakuSource completionHandler:(void(^)(StreamingVideoModel *videoModel, DanDanPlayErrorModel *error))complete {
    
    [VideoNetManager bilibiliVideoURLWithDanmaku:danmaku completionHandler:^(NSDictionary *videosDic, DanDanPlayErrorModel *error) {
        [DanmakuNetManager downThirdPartyDanmakuWithDanmaku:danmaku provider:danmakuSource completionHandler:^(id responseObj, DanDanPlayErrorModel *error) {
            StreamingVideoModel *vm = [[StreamingVideoModel alloc] initWithFileURLs:videosDic fileName:videoName danmaku:danmaku danmakuSource:danmakuSource];
            vm.danmakuDic = responseObj;
            vm.quality = [UserDefaultManager shareUserDefaultManager].defaultQuality;
            complete(vm, error);
        }];
    }];
}

- (void)refreshWithcompletionHandler:(void(^)(DanDanPlayErrorModel *error))complete{
    [DanmakuNetManager GETBiliBiliDanmakuInfoWithAid:_aid page:_page completionHandler:^(BiliBiliVideoInfoModel *responseObj, DanDanPlayErrorModel *error) {
        self.models = responseObj.videos;
        complete(error);
    }];
}

- (instancetype)initWithURL:(NSString *)URL danmakuSource:(DanDanPlayDanmakuSource )danmakuSource {
    if (self = [super init]) {
        self.danmakuSource = danmakuSource;
        if (danmakuSource == DanDanPlayDanmakuSourceBilibili) {
            [ToolsManager bilibiliAidWithPath:URL complectionHandler:^(NSString *aid, NSString *page) {
                self.aid = aid;
                self.page = page.integerValue;
            }];
        }
        else if (danmakuSource == DanDanPlayDanmakuSourceAcfun) {
            [ToolsManager acfunAidWithPath:URL complectionHandler:^(NSString *aid, NSString *index) {
                self.aid = aid;
                self.page = index.integerValue;
            }];
        }
    }
    return self;
}

#pragma mark - 私有方法
- (VideoInfoDataModel *)modelForRow:(NSInteger)row{
    return row < self.models.count ? self.models[row] : nil;
}
@end
