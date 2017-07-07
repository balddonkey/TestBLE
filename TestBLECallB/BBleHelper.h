//
//  BBleHelper.h
//  TestBLECall
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BBleHelperDelegate <NSObject>

- (void)changeMsg:(NSString *)msg;

@end

@interface BBleHelper : NSObject

- (instancetype)initWithDelegate:(id <BBleHelperDelegate>)delegate;

- (void)find;
- (void)close;

- (void)sendNext;

- (void)enqueue:(id)jsonObject;

@end
