//
//  LoadMoreDB.m
//  LoadMoreDBDemo
//
//  Created by do on 2018/7/5.
//  Copyright © 2018年 do. All rights reserved.
//

#define DOCUMENTSPATH   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define LoadMorePath           [DOCUMENTSPATH stringByAppendingPathComponent:@"LoadMore"]
#define FMDB_LoadMorePath      [LoadMorePath stringByAppendingPathComponent:@"LoadMore.sqlite"]

#import "LoadMoreDB.h"

@implementation LoadMoreDB

- (id)init
{
    self = [super init];
    if (self) {
        [self createDatabase];
    }
    return self;
}

- (NSArray *)getAllDatas
{
    NSMutableArray *resultAry = [NSMutableArray arrayWithCapacity:0];
    FMDatabase *db = [self open];
    if (db != nil) {
        NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM LoadMoreList ORDER BY timestamp ASC"];
        FMResultSet *rs = [db executeQuery:sqlString];
        while ([rs next]) {
            TextModel *model = [[TextModel alloc] init];
            model.content = [rs objectForColumn:@"content"];
            model.timestamp = [rs objectForColumn:@"timestamp"];
            [resultAry addObject:model];
        }
        [rs close];
        [db close];
    }
    return resultAry;
}

- (NSArray *)loadMoreDataWithPageNumber:(int)pageNumber
{
    if (pageNumber <= 0) {
        pageNumber = 1;
    }
    NSMutableArray *resultAry = [NSMutableArray arrayWithCapacity:0];
    FMDatabase *db = [self open];
    if (db != nil) {
        //把最新的5条降序排列拿出来 在升序排列
        /*
         先拿最新的 10 9 8 7 6
         再排序变成 6 7 8 9 10
         */
        NSString *sqlString = [NSString stringWithFormat:@"select * from (select * from LoadMoreList order by timestamp desc limit %i,10) t order by timestamp asc", (pageNumber - 1) * 10];
        FMResultSet *rs = [db executeQuery:sqlString];
        while ([rs next]) {
            TextModel *model = [[TextModel alloc] init];
            model.content = [rs objectForColumn:@"content"];
            model.timestamp = [rs objectForColumn:@"timestamp"];
            [resultAry addObject:model];
        }
        [rs close];
        [db close];
    }
    
    return resultAry;
}

- (BOOL)updateTextObjc:(TextModel *)object
{
    FMDatabase *db = [self open];
    if (db != nil) {
        NSString *sqlString = nil;
        sqlString = [NSString stringWithFormat:@"REPLACE INTO LoadMoreList(content, timestamp) values ('%@','%@')", object.content, object.timestamp];
        BOOL suc = [db executeUpdate:sqlString];
        if (suc) {
            NSLog(@"更新成功");
        }
        [db close];
        return suc;
    }
    return NO;
}

#pragma mark - 打开数据库
- (FMDatabase *)open
{
    FMDatabase *db = [FMDatabase databaseWithPath:FMDB_LoadMorePath];
    if (![db open]) {
        NSLog(@"Could not open db.");
        [db close];
        return nil;
    }
    return db;
}

- (void)createDatabase
{
    [self createDBPath:FMDB_LoadMorePath sqlString:@"CREATE TABLE IF NOT EXISTS LoadMoreList(ID integer PRIMARY KEY AUTOINCREMENT, content text, timestamp text, UNIQUE(timestamp))"];
}

- (void)createDBPath:(NSString *)path sqlString:(NSString *)sqlString
{
    [self checkPathExistAndCreate:LoadMorePath];
    FMDatabaseQueue *_queue = [FMDatabaseQueue databaseQueueWithPath:path];
    [_queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sqlString];
    }];
}

- (BOOL)checkPathExistAndCreate:(NSString *)path
{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL result = [manager fileExistsAtPath:path];
    if (!result) {
        result = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        NSAssert(result, @"创建目录失败");
    }
    return result;
}

@end
