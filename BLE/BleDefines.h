//
//  BleDefines.h
//  TestBLECall
//
//  Created by 慧流 on 2017/5/11.
//  Copyright © 2017年 慧流. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

NSString *bcrUUID = @"FFEEEEFF-FFFF-EEEE-FFFF-EEEE00001111";    // 自定义 CLBeaconRegion UUID
NSInteger major = 11;
NSInteger minor = 22;
NSString *bcrIdentifier = @"com.streamind.bcrIdentifier";

NSString *bleServiceUUID = @"9a1544ca-9b93-4e20-8adc-5c96bae71c1e"; //@"6BCF"; //@"FFEE";
NSString *bleCharacteristicUUID = @"bdfc68c7-2a73-4b4b-856d-5c67616ce72a"; //@"50aef763-a606-4caa-b2d9-1a99c99cc54b"; //@"6BD0"; //@"FF01";

NSString *bleServiceUUID2 = @"FFE2";
NSString *bleCharacteristicUUID2 = @"FF02";


NSInteger BLESendByteMaxLength  = 18;
