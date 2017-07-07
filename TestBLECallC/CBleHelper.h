//
//  CBleHelper.h
//  TestBLECall
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

@protocol CBleHelperDelegate <NSObject>

- (void)changeMsg:(NSString *)msg;

@end

@interface CBleHelper : NSObject

- (instancetype)initWithDelegate:(id <CBleHelperDelegate>)delegate;

- (void)call;

- (void)sendMsg:(NSString *)msg;

@end
