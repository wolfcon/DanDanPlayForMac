//
//  ThirdPartySearchViewController.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/2/5.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "ThirdPartySearchViewController.h"
#import "ThirdPartyDanMuChooseViewController.h"
#import "BiliBiliSearchViewModel.h"

@interface ThirdPartySearchViewController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (strong, nonatomic) BiliBiliSearchViewModel *vm;
@property (weak) IBOutlet NSImageView *coverImageView;
@property (weak) IBOutlet NSTextField *titleTextField;
@property (weak) IBOutlet NSTextField *detailTextField;
@end

@implementation ThirdPartySearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.shiBantableView setDoubleAction:@selector(shiBanTableViewDoubleClickRow)];
    [self.episodeTableView setDoubleAction:@selector(episodeTableViewDoubleClickRow)];
}

- (void)refreshWithKeyWord:(NSString *)keyWord completion:(void(^)(NSError *error))completionHandler{
    [self.vm refreshWithKeyWord:keyWord completionHandler:^(NSError *error) {
        _coverImageView.image = [NSImage imageNamed:@"imghold"];
        _titleTextField.stringValue = @"";
        _detailTextField.stringValue = @"";
        [self.shiBantableView reloadData];
        [self.episodeTableView reloadData];
        completionHandler(error);
    }];
}



#pragma mark - 私有方法

- (void)loadInfoView{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSImage *img = [[NSImage alloc] initWithContentsOfURL: [self.vm coverImg]];
       dispatch_async(dispatch_get_main_queue(), ^{
           self.coverImageView.image = img;
       });
    });
    
    self.titleTextField.stringValue = [self.vm shiBanTitle];
    self.detailTextField.stringValue = [self.vm shiBanDetail];
}

- (void)shiBanTableViewDoubleClickRow{
    NSInteger row = [self.shiBantableView clickedRow];
    //判断改行是否为新番
    if ([self.vm isShiBanForRow: row]) {
        NSString *seasonID = [self.vm seasonIDForRow: row];
        if (seasonID) {
            [JHProgressHUD showWithMessage:@"你不能让我加载, 我就加载" parentView: self.episodeTableView];
            [self.vm refreshWithSeasonID:seasonID completionHandler:^(NSError *error) {
                [JHProgressHUD disMiss];
                [self loadInfoView];
                [self.episodeTableView reloadData];
            }];
        }
    }else{
        NSString *aid = [self.vm aidForRow: row];
        if (aid) {
            ThirdPartyDanMuChooseViewController *vc = [[ThirdPartyDanMuChooseViewController alloc] initWithVideoID: aid];
            [self presentViewControllerAsSheet: vc];
        }
    }
}

- (void)episodeTableViewDoubleClickRow{
    if (![self.vm infoArrCount]) return;
    [JHProgressHUD showWithMessage:@"你不能让我加载, 我就加载" parentView: self.view];
    [self.vm downDanMuWithRow:[self.episodeTableView clickedRow] completionHandler:^(NSError *error) {
        [JHProgressHUD disMiss];
    }];
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if ([tableView.identifier isEqualToString:@"shiBanTableView"]) {
        return [self.vm shiBanArrCount];
    }else{
        return [self.vm infoArrCount];
    }
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    if ([tableColumn.identifier isEqualToString:@"shiBanCell"]){
        NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        cell.textField.stringValue = [self.vm shiBanTitleForRow: row];
        return cell;
    }else if ([tableColumn.identifier isEqualToString:@"episodeCell"]){
        NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        cell.textField.stringValue = [self.vm episodeTitleForRow: row];
        return cell;
    }
    return nil;
}

#pragma mark - 懒加载
- (BiliBiliSearchViewModel *)vm {
	if(_vm == nil) {
		_vm = [[BiliBiliSearchViewModel alloc] init];
	}
	return _vm;
}

@end