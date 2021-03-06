//
//  DanMuFilterCell.m
//  DanDanPlayForMac
//
//  Created by JimHuang on 16/2/13.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "DanMuFilterCell.h"
#import "UseFilterExpressionCell.h"
#import "FilterNetManager.h"
#import "ColorButton.h"
#import "NSOpenPanel+Tools.h"

@interface DanMuFilterCell()<NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate>
@property (weak) IBOutlet NSButton *importButton;
@property (weak) IBOutlet NSButton *exportButton;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet ColorButton *updateRuleButton;
@property (strong, nonatomic) NSMutableArray <NSDictionary *>*userFilterArr;
@end

@implementation DanMuFilterCell
- (void)controlTextDidEndEditing:(NSNotification *)obj{
    NSTextView *view = obj.userInfo[@"NSFieldEditor"];
    NSInteger index = [self.tableView rowForView: view];
    if (index >= self.userFilterArr.count) return;
    NSMutableDictionary *dic = [self.userFilterArr[index] mutableCopy];
    dic[@"text"] = [NSString stringWithFormat:@"%@", view.string];
    self.userFilterArr[index] = dic;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.tableView setDoubleAction:@selector(doubleClick:)];
    
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.importButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttributes:@{NSForegroundColorAttributeName:[NSColor blueColor], NSUnderlineStyleAttributeName:@2} range:titleRange];
    [self.importButton setAttributedTitle:colorTitle];
    
    colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.exportButton attributedTitle]];
    titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttributes:@{NSForegroundColorAttributeName:[NSColor blueColor], NSUnderlineStyleAttributeName:@2} range:titleRange];
    
    [self.exportButton setAttributedTitle: colorTitle];
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.userFilterArr.count;
}

#pragma mark - NSTableViewDelegate
- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    if ([tableColumn.identifier isEqualToString:@"FilterRulerCell"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        NSString *text = self.userFilterArr[row][@"text"];
        cell.textField.text = text;
        cell.textField.delegate = self;
        return cell;
    }
    else if ([tableColumn.identifier isEqualToString:@"UseFilterExpressionCell"]) {
        UseFilterExpressionCell *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        cell.OKButton.state = [self.userFilterArr[row][@"state"] boolValue];
        __weak typeof(self)weakSelf = self;
        [cell setClickBlock:^(NSInteger state) {
            NSMutableDictionary *dic = [weakSelf.userFilterArr[row] mutableCopy];
            dic[@"state"] = @(state);
            weakSelf.userFilterArr[row] = dic;
        }];
        return cell;
    }
    return nil;
}

#pragma mark - 私有方法
- (IBAction)importRules:(NSButton *)sender {
    NSOpenPanel* openPanel = [NSOpenPanel chooseFilePanelWithTitle:@"导入屏蔽列表" defaultURL:nil];
    [openPanel beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton){
            NSArray *arr = [NSArray arrayWithContentsOfURL: openPanel.URL];
            if (arr) {
                self.userFilterArr = [NSMutableArray arrayWithArray:arr];
                [self.tableView reloadData];
            }
        }
    }];
}

- (IBAction)exportRules:(NSButton *)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setTitle:@"导出屏蔽列表"];
    [panel setCanCreateDirectories: YES];
    [panel setNameFieldStringValue:@"list.ls"];
    [panel beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
            [self.userFilterArr writeToURL:panel.URL atomically:YES];
    }];
}

- (IBAction)clickCloudFilterList:(NSButton *)sender {
    [FilterNetManager filterWithCompletionHandler:^(NSArray *responseObj, NSError *error) {
        [self.userFilterArr addObjectsFromArray:responseObj];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.userFilterArr.count, responseObj.count)] withAnimation:NSTableViewAnimationEffectFade];
        [self.tableView endUpdates];
    }];
}

- (void)rightMouseDown:(NSEvent *)theEvent{
    NSIndexSet *indexSet = [self.tableView selectedRowIndexes];
    [self.userFilterArr removeObjectsAtIndexes:indexSet];
    [self.tableView removeRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationEffectFade];
}

- (void)doubleClick:(NSTableView *)tableView{
    [self.userFilterArr addObject:@{@"text":@"", @"state":@0}];
    [tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.userFilterArr.count] withAnimation:NSTableViewAnimationEffectFade];
}

- (IBAction)updateRules:(NSButton *)sender {
    [UserDefaultManager shareUserDefaultManager].userFilterArr = self.userFilterArr;
}

#pragma mark - 懒加载

- (NSMutableArray *)userFilterArr {
    if(_userFilterArr == nil) {
        _userFilterArr = [UserDefaultManager shareUserDefaultManager].userFilterArr;
    }
    return _userFilterArr;
}

@end
