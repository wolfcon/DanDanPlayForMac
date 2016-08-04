//
//  PlayerSubtitleViewController.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/7/19.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "PlayerSubtitleViewController.h"
#import "PlayerSubtitleFontSizeCell.h"
#import "PlayerSubtitleTimeOffsetCell.h"
#import "OnlyButtonCell.h"
#import "PlayerSubtitleSwitchCell.h"

@interface PlayerSubtitleViewController ()<NSTableViewDataSource, NSTabViewDelegate>

@end

@implementation PlayerSubtitleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 4;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        PlayerSubtitleSwitchCell *cell = [tableView makeViewWithIdentifier:@"PlayerSubtitleSwitchCell" owner:nil];
        cell.touchButtonCallBack = self.touchSwitchButtonCallBack;
        return cell;
    }
    else if (row == 1) {
        PlayerSubtitleFontSizeCell *cell = [tableView makeViewWithIdentifier:@"PlayerSubtitleFontSizeCell" owner:nil];
        cell.fontSizeChangeCallBack = self.fontSizeChangeCallBack;
        return cell;
    }
    else if (row == 2) {
        PlayerSubtitleTimeOffsetCell *cell = [tableView makeViewWithIdentifier:@"PlayerSubtitleTimeOffsetCell" owner:self];
        cell.timeOffsetCallBack = self.timeOffsetCallBack;
        return cell;
    }
    else if (row == 3) {
        OnlyButtonCell *cell = [tableView makeViewWithIdentifier:@"OnlyButtonCell" owner:self];
        cell.button.title = @"选择本地字幕文件";
        cell.buttonDownBlock = self.chooseLoactionFileCallBack;
        return cell;
    }
    return nil;
}

#pragma mark - NSTabViewDelegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if (row == 0 || row == 1) {
        return 60;
    }
    else if (row == 2) {
        return 102;
    }
    else if (row == 3) {
        return 50;
    }
    return 0;
}


@end