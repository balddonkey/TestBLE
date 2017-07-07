//
//  CBleHelper.m
//  TestBLECall
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import "CBleHelper.h"
#import "BleDefines.h"

@interface CBleHelper () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@property (assign) id <CBleHelperDelegate> delegate;

@property (strong, nonatomic) CBMutableCharacteristic *characteristic;
@property (strong, nonatomic) CBMutableCharacteristic *characteristic2;


@end

@implementation CBleHelper

- (instancetype)initWithDelegate:(id <CBleHelperDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)call {
    
    // 开启蓝牙扫描
//    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:bleServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    
    [self install];
    
    // 开启Beacon Region 广播，唤醒 App
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:bcrUUID] major:major minor:minor identifier:bcrIdentifier];
    NSMutableDictionary *data = [[region peripheralDataWithMeasuredPower:@(-53)] mutableCopy];
    NSLog(@"data: %@", data.description);
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:bleServiceUUID], [CBUUID UUIDWithString:bleServiceUUID2]]}];
    [self.peripheralManager startAdvertising:data];
    
    [self.delegate changeMsg:@"开始广播Beacon信号以及扫描监听蓝牙信号"];
    
}
- (void)install {
    
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString: bleCharacteristicUUID]
                                                                          properties:CBCharacteristicPropertyNotify |	CBCharacteristicPropertyRead | CBCharacteristicPropertyRead value:nil
                                                                         permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:bleServiceUUID] primary:YES];
    service.characteristics = @[self.characteristic];
    self.characteristic2 = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString: bleCharacteristicUUID2]
                                                             properties:CBCharacteristicPropertyNotify |	CBCharacteristicPropertyRead | CBCharacteristicPropertyRead value:nil
                                                            permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    CBMutableService *service2 = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:bleServiceUUID2] primary:YES];
    service2.characteristics = @[self.characteristic2];
    [self.peripheralManager addService:service2];
}

- (void)hangup {
    [self.peripheralManager stopAdvertising];
}

- (void)sendMsg:(NSString *)msg {
    [self.peripheralManager updateValue:[msg dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
}

#pragma mark - CBPeripheralManagerDelegate method
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    NSString *msg = nil;
    if (peripheral.state == CBManagerStatePoweredOn) {
        msg = @"BCR模拟器就绪";
    } else {
        msg = [NSString stringWithFormat:@"BCR模拟器出错: %ld", (long)peripheral.state];
    }
    [self.delegate changeMsg:msg];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    [self.delegate changeMsg:@"did subscribe"];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"did recive read request: %@", [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding]);
    request.value = [@"123" dataUsingEncoding:NSUTF8StringEncoding];
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequest:(CBATTRequest *)request {
    NSLog(@"did recive write request: %@", [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding]);
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

@end
