//
//  BBleHelper.m
//  TestBLECall
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import "BBleHelper.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "BleDefines.h"

NSString *kBCRegionDidRegister = @"com.streamind.kBCRegionDidRegister";
NSString *start = @"com.ming.s";
NSString *end = @"com.ming.e";

@interface BBleHelper () <CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (weak, nonatomic) id <BBleHelperDelegate> delegate;

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *characteristic;

@property (strong, nonatomic) NSMutableData *data;
@property (assign, nonatomic) BOOL receiveStart;
@property (assign, nonatomic) NSInteger dataLength;

@property (strong, nonatomic) NSMutableArray *sendQueue;
@property (strong, nonatomic) NSData *sendingData;
@property (assign, nonatomic) NSInteger sendingIndex;

@property (assign, nonatomic) NSInteger reciveTimes;


@end

@implementation BBleHelper

- (instancetype)initWithDelegate:(id <BBleHelperDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self setup];
    }
    return self;
}

- (void)registerBCRegion {
    BOOL didRegister = [[[NSUserDefaults standardUserDefaults] objectForKey:kBCRegionDidRegister] boolValue];
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region isKindOfClass:[CLBeaconRegion class]]) {
            CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
            NSLog(@"UUID: %@", beaconRegion.proximityUUID.UUIDString);
        }
    }
    if (!didRegister) {
//        [self.delegate changeMsg:@"注册区域监听"];
//        [self.locationManager startMonitoringForRegion:[[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:bcrUUID] identifier:bcrIdentifier]];
//        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kBCRegionDidRegister];
    }
}

- (void)setup {
    // ...
    self.sendQueue = [NSMutableArray array];
    self.reciveTimes = 0;
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    
}

- (void)enqueue:(id)jsonObject {
    if (![NSJSONSerialization isValidJSONObject:jsonObject]) {
        NSLog(@"enqueue error: invalid json object");
        return;
    }
    NSError *error;
    NSData *jsData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:&error];
//    NSLog(@"%p", jsData);
    if (error) {
        NSLog(@"enqueue error: %@", error.localizedDescription);
    } else {
        NSData *startData = [start dataUsingEncoding:NSUTF8StringEncoding];
        NSString *lengthStr = [NSString stringWithFormat:@"%ld", jsData.length];
        NSData *lengthData = [lengthStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *estr = [[NSString alloc] initWithData:jsData encoding:NSUTF8StringEncoding];
        NSLog(@"enqueue jsData: %@", estr);
        [self.sendQueue addObject:startData];
        [self.sendQueue addObject:lengthData];
        [self.sendQueue addObject:jsData];
        [self sendNext];
    }
}

- (NSMutableData *)data {
    if (!_data) {
        _data = [NSMutableData new];
    }
    return _data;
}

- (void)find {
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:bleServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    [self.delegate changeMsg:@"开始查找"];
}

- (void)close {
    [self.delegate changeMsg:@"停止广播"];
}

#pragma mark - CBCentralManagerDelegate method
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *msg = nil;
    if (central.state == CBManagerStatePoweredOn) {
        msg = @"接收器就绪";
    } else {
        msg = [NSString stringWithFormat:@"接收器出错: %ld", (long)central.state];
    }
    [self.delegate changeMsg:msg];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Find: %@", advertisementData);
    [central stopScan];
    self.peripheral = peripheral;
    [self.delegate changeMsg:[NSString stringWithFormat:@"发现蓝牙设备: %@, 正在尝试连接...", peripheral.identifier.UUIDString]];
    [central connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    [self.delegate changeMsg:[NSString stringWithFormat:@"Faile to connect peripheral: %@", error.localizedDescription]];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    peripheral.delegate = self;
    self.reciveTimes = 0;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:bleServiceUUID]]];
    [self.delegate changeMsg:[NSString stringWithFormat:@"蓝牙设备: %@, 连接成功", peripheral.identifier.UUIDString]];
}

#pragma mark - CBPeripheralDelegate method
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    // ...
    NSLog(@"did modify services: %@", invalidatedServices);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    NSLog(@"did discover service: %ld", peripheral.services.count);
    [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:bleCharacteristicUUID]] forService:obj];
        [self.delegate changeMsg:[NSString stringWithFormat:@"已发现Service: %@", obj.UUID.UUIDString]];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    NSLog(@"did discover chars: %ld", service.characteristics.count);
    if (service.characteristics.count > 0 ) {
        CBCharacteristic *characteristic = service.characteristics[0];
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
//        [peripheral discoverDescriptorsForCharacteristic:characteristic];
        self.characteristic = characteristic;
        [self.delegate changeMsg:@"已发现Characteristic"];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    if (characteristic.descriptors > 0) {
//        for (CBDescriptor *descriptor in characteristic.descriptors) {
//            NSData *data = [@"diuleilaomou" dataUsingEncoding:NSUTF8StringEncoding];
//            [peripheral writeValue:data forDescriptor:descriptor];
//        }
//    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"did disconnect");
    if (peripheral == self.peripheral) {
        self.peripheral = nil;
        self.characteristic = nil;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
//    [self.delegate changeMsg:[NSString stringWithFormat:@"did update value: %@", [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]]];
//    NSLog(@"len: %ld", characteristic.value.length);
//    NSLog(@"data: %@", characteristic.value);
//    return;

//    Byte byte[2];
//    [characteristic.value getBytes:byte range:NSMakeRange(0, 2)];
//    if (byte[0] == 1) {
//        self.data = nil;
////        NSLog(@"new msg: %d", byte[1]);
//        NSData *sub = [characteristic.value subdataWithRange:NSMakeRange(2, characteristic.value.length - 2)];
//        [self.data appendData:sub];
//    }
//    else if (byte[0] == 2) {
//        NSData *sub = [characteristic.value subdataWithRange:NSMakeRange(2, characteristic.value.length - 2)];
//        [self.data appendData:sub];
//    }else if (byte[0] == 0) {
//        NSData *sub = [characteristic.value subdataWithRange:NSMakeRange(2, characteristic.value.length - 2)];
//        [self.data appendData:sub];
//        NSString *rec = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
//        NSLog(@"rec: %@", rec);
//        self.reciveTimes ++;
//        NSLog(@"times: %ld", self.reciveTimes);
//    }
    
    NSString *tryParse = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    NSLog(@"receive new: %ld", characteristic.value.length);
    if ([tryParse isEqualToString:start]) {
        if (self.data.length < self.dataLength) {
            NSLog(@"Pack lose, length: %ld, receive: %ld", self.dataLength, self.data.length);
            [self.delegate changeMsg:[NSString stringWithFormat:@"Pack lose, length: %ld, receive: %ld", self.dataLength, self.data.length]];
        }
        
        self.receiveStart = YES;
        self.dataLength = -1;
        self.data = nil;
        
        [self.delegate changeMsg:@"Receive new: "];
    } else if (self.receiveStart) {
        NSInteger length = [tryParse integerValue];
        self.dataLength = length;
        if (length <= 0) {
            NSLog(@"Receive new data length: %ld, maybe an error occur", length);
        }
        self.receiveStart = NO;
    } else {
        if (self.data.length < self.dataLength) {
            [self.data appendData:characteristic.value];
        } else {
            NSLog(@"Receive to much data, length: %ld, more than data length: %ld", self.data.length, self.dataLength);
        }
        if (self.data.length >= self.dataLength) {
            NSString *result = [[NSString alloc] initWithData:[self.data subdataWithRange:NSMakeRange(0, self.dataLength)] encoding:NSUTF8StringEncoding];
            if (result) {
                NSLog(@"did receive: \n%@", result);
                [self.delegate changeMsg:result];
            } else {
                NSLog(@"Can not parse data");
                [self.delegate changeMsg:@"Can not parse data"];
            }
        }
    }
    
//    NSString *event = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
//    if (event) {
//        NSLog(@"event: %@", event);
////        if ([event isEqualToString:@"msg"]) {
////            self.data = nil;
//////            [peripheral readValueForCharacteristic:characteristic];
////            return;
////        }
//    }
//    [self.data appendData:characteristic.value];
//    if (characteristic.value.length < 20) {
//        NSString *res = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
//        if (res) {
//            NSLog(@"Res: %@", res);
//        } else {
//            NSLog(@"Res convert error");
//        }
//        self.data = nil;
//    } else {
////        [peripheral readValueForCharacteristic:characteristic];
//    }
}

- (void)sendData {
    if (self.sendingData) {
        NSInteger length = self.sendingData.length - BLESendByteMaxLength * self.sendingIndex;
        if (length < 0) {
            NSLog(@"did send data: %@", self.sendingData);
            self.sendingIndex = 0;
            self.sendingData = nil;
            [self sendData];
            return;
        }
        length = MIN(BLESendByteMaxLength, MAX(0, length));
        NSMutableData *elem = [NSMutableData new];
        NSData *data = [self.sendingData subdataWithRange:NSMakeRange(BLESendByteMaxLength * self.sendingIndex, length)];
        [elem appendData:data];
//        NSLog(@"send next: %ld, %d, %d\n%@", length, byte[0], byte[1], elem);
//        if (str) {
//            NSLog(@"str: %@", str);
//        }
        
        if (self.peripheral && self.characteristic) {
//            NSLog(@"sub %@", elem);
            [self.peripheral writeValue:elem forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
        } else {
            self.sendingIndex = 0;
            [self.sendQueue insertObject:self.sendingData atIndex:0];
            self.sendingData = nil;
            NSLog(@"Connect losed");
        }
    } else {
        [self sendNext];
    }
}

- (void)sendNext {
    if (_sendingData) {
        return;
    }
    if (self.sendQueue.count > 0) {
        NSLog(@"remove");
        self.sendingIndex = 0;
        self.sendingData = [self.sendQueue firstObject];
//        NSLog(@"f: %p", self.sendingData);
        [self.sendQueue removeObjectAtIndex:0];
        [self sendData];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    [self.delegate changeMsg:[NSString stringWithFormat:@"did write value"]];
    
    self.sendingIndex++;
    [self sendData];
}

#pragma mark - CLLocationManagerDelegate method

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self registerBCRegion];
        [self.delegate changeMsg:@"获取授权成功"];
    } else {
        [self.delegate changeMsg:@"获取授权失败"];
    }
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    if (state == CLRegionStateInside) {
        [self.delegate changeMsg:@"进入区域"];
//        [self find];
    } else {
        [self.delegate changeMsg:@"离开区域"];
        [self close];
    }
}


@end
