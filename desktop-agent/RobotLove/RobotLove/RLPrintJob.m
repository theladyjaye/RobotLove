//
//  RLPrintJob.m
//  RobotLove
//
//  Created by Adam Venturella on 7/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RLPrintJob.h"
#import "RLPrintJob+Bluetooth.h"
#import <IOBluetooth/IOBluetooth.h>
 
static inline double radians (double degrees) {return degrees * M_PI/180;} 

@implementation RLPrintJob

+ (RLPrintJob *) printJobWithBluetoothDevice:(IOBluetoothDevice *)device
{
    RLPrintJob * job = [[RLPrintJob alloc] initWithBluetoothDevice:device];
    return [job autorelease];
}

- (id)initWithBluetoothDevice:(IOBluetoothDevice *)aDevice
{
    self = [super init];
    
    if(self)
    {
        jobType   = RLPrintJobTypeBluetooth;
        printTime = 70.0;
        device    = aDevice;
        
        [device retain];
    }
    
    return self;
}

- (void)print:(NSData *)data callback:(RLPrintJobCallback)completeCallback
{    
    callback = [completeCallback copy];
    
    NSImage * image  = [[NSImage alloc] initWithData:data];
    //NSRect imageRect = NSMakeRect(0.0, 0.0, 612.0, 612.0);
    NSRect offscreenRect = NSMakeRect(0.0f, 0.0f, 1216.0f, 912.0f);
    NSBitmapImageRep* offscreenRep = nil;
    
    offscreenRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                           pixelsWide:offscreenRect.size.width
                                                           pixelsHigh:offscreenRect.size.height
                                                        bitsPerSample:8
                                                      samplesPerPixel:4
                                                             hasAlpha:YES
                                                             isPlanar:NO
                                                       colorSpaceName:NSCalibratedRGBColorSpace
                                                         bitmapFormat:0
                                                          bytesPerRow:(4 * offscreenRect.size.width)
                                                         bitsPerPixel:32];
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:offscreenRep]];
    
    //NSRect resizedRect = NSMakeRect(0, 0, 800, 800); // 912x912 cuts off some of the image, this is a trial and error number
    NSRect resizedRect = NSMakeRect(0, 0, 860, 860);
    
    CGImageRef resizedImageRef  = [image CGImageForProposedRect:&resizedRect context:[NSGraphicsContext currentContext] hints:nil];
    NSImage *resizedImage = [[NSImage alloc] initWithCGImage:resizedImageRef size:resizedRect.size];
    
    // Begin Rotation
    CGSize rotatedSize = [resizedImage size];
    //NSImage* rotatedImage = [[NSImage alloc] initWithSize:rotatedSize] ;
    
    
    NSAffineTransform* transform = [NSAffineTransform transform] ;
    
    // In order to avoid clipping the image, translate
    // the coordinate system to its center
    [transform translateXBy:+rotatedSize.width/2
                        yBy:+rotatedSize.height/2] ;
    // then rotate
    [transform rotateByDegrees:90.0] ;
    
    // Then translate the origin system back to
    // the bottom left
    [transform translateXBy:-rotatedSize.width/2
                        yBy:-rotatedSize.height/2] ;
    
    [transform concat] ;
    // 56 = (912 - 800) / 2 
    // 70 = adjustments to make it fit on the top
    //[resizedImage drawAtPoint:NSMakePoint(56.0, -70.0) fromRect:resizedRect operation:NSCompositeCopy fraction:1.0];
    [resizedImage drawAtPoint:NSMakePoint(26.0, -26.0) fromRect:resizedRect operation:NSCompositeCopy fraction:1.0];
    
    // End Rotation
    
    
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSData * jpeg = [offscreenRep representationUsingType:NSJPEGFileType 
                                               properties:nil];
    [resizedImage release];
    [offscreenRep release];
    [image release];
    
    //[jpeg writeToFile: @"/Users/dev/Desktop/test.jpg"
    //       atomically: NO];
    
    
    
    //callback();
    //return;
    
    printData = jpeg;
    [printData retain];
    
    if(jobType == RLPrintJobTypeBluetooth)
    {
        NSLog(@"Sending to Bluetooth Printer");
        [self printBluetooth];
    }
}

- (void)delayForPrintTime
{
    NSLog(@"Waiting for print job to complete");
    [NSTimer scheduledTimerWithTimeInterval:printTime target:self selector:@selector(timerDidFireMethod:) userInfo:nil repeats:NO];
}

- (void)timerDidFireMethod:(NSTimer*)theTimer
{
    NSLog(@"Print job complete");
    callback();
}

- (void)dealloc
{
    NSLog(@"Cleaning up Print Job");
    
    [callback release];
    [printData release];
    
    if(jobType == RLPrintJobTypeBluetooth)
    {
        [device release];
        [session release];
        [transferServices release];
    }
    
    [super dealloc];
}


@end
