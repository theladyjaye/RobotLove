//
//  RLPrintJob.h
//  RobotLove
//
//  Created by Adam Venturella on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

typedef enum {
    RLPrintJobTypePrinter,
    RLPrintJobTypeBluetooth
    
} RLPrintJobType;

typedef void (^RLPrintJobCallback)();

@interface RLPrintJob : NSObject
{
    IOBluetoothSDPServiceRecord *record;
    OBEXFileTransferServices *transferServices;
    IOBluetoothOBEXSession * session;
    IOBluetoothDevice * device;
    
    RLPrintJobType jobType;
    NSData * printData;
    RLPrintJobCallback callback;
    
    NSTimeInterval printTime;
}

+ (RLPrintJob *) printJobWithBluetoothDevice:(IOBluetoothDevice *)device;
- (id)initWithBluetoothDevice:(IOBluetoothDevice *)aDevice;
- (void)print:(NSData *)data callback:(RLPrintJobCallback)completeCallback;
- (void)delayForPrintTime;
@end
