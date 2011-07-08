//
//  RLPrintJob+BluetoothDelegate.m
//  RobotLove
//
//  Created by Adam Venturella on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RLPrintJob+Bluetooth.h"
#import <IOBluetooth/IOBluetooth.h>
@implementation RLPrintJob(Bluetooth)

- (void)printBluetooth
{
    //[self delayForPrintTime];
    //return;
    
    record           = [device getServiceRecordForUUID:[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassOBEXObjectPush]];
    session          = [[IOBluetoothOBEXSession alloc]initWithSDPServiceRecord:record];
    transferServices = [OBEXFileTransferServices withOBEXSession: session];
    
    [transferServices retain];
    [transferServices setDelegate:self];
    
    if([transferServices connectToObjectPushService] == kOBEXSuccess)
    //if([transferServices connectToFTPService] == kOBEXSuccess)
    {
        NSLog(@"Waiting for Push Service Connection");
    }
    else
    {
        NSLog(@"Upable to connect to push object service!");
    }
     
}


- (void)fileTransferServicesAbortComplete: (OBEXFileTransferServices*)service
                                     error:(OBEXError)inError 
{
    NSLog(@"fileTransferServicesAbortComplete has been called");
}

- (void)fileTransferServicesDisconnectionComplete: (OBEXFileTransferServices*)service
                                             error:(OBEXError)inError 
{
    NSLog(@"fileTransferServicesDisconnectionComplete has been called");
    
}


- (void)fileTransferServicesConnectionComplete: (OBEXFileTransferServices*)service
                                          error:(OBEXError)inError 
{
    NSLog(@"connection complete");
    
    // instagram is all jpeg
    // we could just leave it nil
    [service sendData:printData type:@"image/jpeg" name:@"photo.jpg"];
    //NSString * path = [[NSBundle mainBundle] pathForImageResource:@"a31e76d335204ae4bb2b3da5dad69d70_7.jpg"];
    //[transferServices sendFile:path];
    
}

- (void)fileTransferServicesSendFileProgress: (OBEXFileTransferServices*)service
                             transferProgress:(NSDictionary*)inProgressDescription 
{    
    NSLog(@"Progress");
}

- (void)fileTransferServicesSendFileComplete: (OBEXFileTransferServices*)service
                                        error:(OBEXError)inError 
{
    NSLog(@"Done Sending... Now Printing");
    [service disconnect];
    [self delayForPrintTime];
}


@end
