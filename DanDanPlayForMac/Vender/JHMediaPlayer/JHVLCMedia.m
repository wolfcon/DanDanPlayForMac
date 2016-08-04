//
//  JHVLCMedia.m
//  DanWanPlayer
//
//  Created by JimHuang on 16/1/13.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "JHVLCMedia.h"
@interface JHVLCMedia()<VLCMediaDelegate>
@property (nonatomic, copy) complete returnBlock;
@end
@implementation JHVLCMedia
- (void)parseWithBlock:(complete)block{
    self.returnBlock = block;
    self.delegate = self;
    [self parseWithOptions:VLCMediaParseLocal];
}

#pragma mark - VLCMediaDelegate
- (void)mediaDidFinishParsing:(VLCMedia *)aMedia {
    self.returnBlock(aMedia);
}

- (void)media:(VLCMedia *)aMedia metaValueChangedFrom:(id)oldValue forKey:(NSString *)key {
    
}

- (void)mediaMetaDataDidChange:(VLCMedia *)aMedia {
    
}

- (instancetype)initWithURL:(NSURL *)anURL {
    return (self = [super initWithURL:anURL]);
}

- (instancetype)initWithPath:(NSString *)aPath {
    return [self initWithURL: [NSURL fileURLWithPath: aPath]];
}
@end
