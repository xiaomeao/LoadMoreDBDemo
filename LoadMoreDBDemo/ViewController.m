//
//  ViewController.m
//  LoadMoreDBDemo
//
//  Created by do on 2018/7/5.
//  Copyright © 2018年 do. All rights reserved.
//

#import "ViewController.h"
#import "LoadMoreDB.h"
#import "TextCell.h"
#import "TextModel.h"
#import "MJRefresh.h"

#define WEAKSELF                    __weak typeof(self) weakSelf = self;

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) LoadMoreDB *database;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, assign) BOOL canLoadMore;
@property (nonatomic, assign) int pageNumber;
@end

@implementation ViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    //兼容ios11，修复pop时UIScrollView的子类会发生一个偏移动画
    if (@available(iOS 11.0, *)) {
        [UIScrollView appearance].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    _canLoadMore = NO;
    _pageNumber = 1;
    _dataArray = [[NSMutableArray alloc] initWithCapacity:0];
    _database = [[LoadMoreDB alloc] init];
    [self createTableView];
}

- (void)createTableView
{
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableHeaderView = [[UIView alloc] init];
    _tableView.tableFooterView = [[UIView alloc] init];
    [_tableView registerNib:[UINib nibWithNibName:@"TextCell" bundle:nil] forCellReuseIdentifier:@"TextCell"];
    
    WEAKSELF
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadingDBDatas];
    }];
    header.lastUpdatedTimeLabel.hidden = YES;
    self.tableView.mj_header = header;
    
    NSArray *array = [_database loadMoreDataWithPageNumber:_pageNumber];
    if (array.count > 0) {
        [_dataArray addObjectsFromArray:array];
        [_tableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollViewToBottom:YES];
            if (array.count >= 10) {
                _canLoadMore = YES;
                _pageNumber++;
                self.tableView.mj_header.hidden = NO;
            }
            else {
                self.tableView.mj_header.hidden = YES;
            }
        });
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    if([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]){
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    TextCell *cell = (TextCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TextCell" owner:nil options:nil] firstObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    TextModel *model = _dataArray[indexPath.row];
    cell.contentLabel.text = model.content;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_dataArray.count > 0) {
        return _dataArray.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}

- (void)loadingDBDatas
{
    NSInteger scrollToIndex = _dataArray.count;
    NSArray *array = [_database loadMoreDataWithPageNumber:_pageNumber];
    if (array.count > 0) {
        NSRange rang = NSMakeRange(0, array.count);
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:rang];
        [_dataArray insertObjects:array atIndexes:indexSet];
        [_tableView reloadData];
        if (_dataArray.count > 0) {
            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_dataArray count] - scrollToIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        if (array.count < 10) {
            _canLoadMore = NO;
            [_tableView.mj_header endRefreshing];
            _tableView.mj_header.hidden = YES;
        }
        else {
            _canLoadMore = YES;
            _pageNumber++;
            [_tableView.mj_header endRefreshing];
        }
    }
    else {
        [_tableView.mj_header endRefreshing];
        _tableView.mj_header.hidden = YES;
    }
}

- (void)scrollViewToBottom:(BOOL)animated
{
    if (_dataArray.count > 0) {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_dataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - 
- (IBAction)addAction:(id)sender 
{
    NSArray *array = [_database getAllDatas];
    TextModel *model = [self getModel:array.count + 1];
    [_database updateTextObjc:model];
    
    [_dataArray addObject:model];
    [_tableView reloadData];
}

- (TextModel *)getModel:(NSInteger)index
{
    NSString *timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
    TextModel *model = [[TextModel alloc] init];
    model.content = [NSString stringWithFormat:@"第%li",(long)index];
    model.timestamp = timestamp;
    return model;
}

@end
