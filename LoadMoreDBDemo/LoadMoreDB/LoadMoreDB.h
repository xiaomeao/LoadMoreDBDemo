//
//  LoadMoreDB.h
//  LoadMoreDBDemo
//
//  Created by do on 2018/7/5.
//  Copyright © 2018年 do. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
#import "TextModel.h"

@interface LoadMoreDB : NSObject

/**
 获取所有数据
 */
- (NSArray *)getAllDatas;

/**
 分页获取

 @param pageNumber 默认从第一页获取
 */
- (NSArray *)loadMoreDataWithPageNumber:(int)pageNumber;

/**
 更新或插入数据
 */
- (BOOL)updateTextObjc:(TextModel *)object;

@end
