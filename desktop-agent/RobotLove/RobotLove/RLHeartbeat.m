// Copyright 2011 Adam Venturella
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "RLHeartbeat.h"
#import "CouchDB.h"
#import "RLPrintJob.h"
#import <IOBluetooth/IOBluetooth.h>

static NSInteger kLastSeq;
static NSInteger kMaxSeq;
static NSInteger kPageSize;

@implementation RLHeartbeat

+ (void)initialize
{
    NSNumber * lastSeq = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"last_seq"];
    
    kLastSeq  = lastSeq ? [lastSeq integerValue] : 1;
    kMaxSeq   = -1;
    kPageSize = 5;
}

- (id)init
{
    self = [super init];
    
    
    if (self) 
    {  
        NSString * path = [[NSBundle mainBundle] pathForResource:@"RobotLove-Config" ofType:@"plist"];
        
        config     = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
        couchdb    = [[CouchDB alloc] init];
        queue      = [[NSMutableArray alloc] initWithCapacity:kPageSize];
        
        [self initializePrinter];
        
    }
    
    return self;
}

- (void)initializePrinter
{
    NSLog(@"Initialize Printer");
    // only have 1 bluetooth device connected
    NSArray * devices = [IOBluetoothDevice pairedDevices];
    printer = [devices objectAtIndex:0];
    [printer retain];
    
    
    //NSString * path = [[NSBundle mainBundle] pathForImageResource:@"c3bb6513ba5349148f69b4727aa26efe_7"];
    //NSData * data = [NSData dataWithContentsOfFile:path];
    //[self print_image:data];
    //return;
    
    [printer performSDPQuery:self];
    
}

- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    if(status == kIOReturnSuccess)
    {
        if(kLastSeq == 1)
        {
            NSLog(@"First Run");
            [self firstrun];   
        }
        else
        {
            NSLog(@"Sync");
            //NSString * path = [[NSBundle mainBundle] pathForImageResource:@"c3bb6513ba5349148f69b4727aa26efe_7"];
            //NSData * data = [NSData dataWithContentsOfFile:path];
            //[self print_image:data];
            
            [self sync];
        }
    }
    else
    {
        NSLog(@"BLUETOOTH QUERY ERROR");
    }
    
}

- (void)firstrun
{
    [self create_database];
}

- (void)create_database
{
    NSString * database = [config valueForKey:@"local_database"];
    
    if(database != nil)
    {
        [couchdb create_database:database callback:^(BOOL ok, NSDictionary * data)
        {    
            [self sync];
        }];
    }
    else
    {
        // Database was not defined
    }
}

- (void)sync
{
    NSString * localdb  = [config valueForKey:@"local_database"];
    NSString * remotedb = [config valueForKey:@"remote_database"];
    
    [couchdb replicate:remotedb to:localdb callback:^(BOOL ok, NSDictionary * data)
    {
        if(ok)
        {
            NSLog(@"Sync Complete");
            NSNumber * maxSeq = [data objectForKey:@"source_last_seq"];
            kMaxSeq = [maxSeq intValue];
            [self hydrate_queue];
        }
        else
        {
            NSLog(@"Sync Failed");
        }

    }];
}

- (void)hydrate_queue
{
    if(kLastSeq < kMaxSeq)
    {
        NSString * database   = [config valueForKey:@"local_database"];
        
        NSDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:kLastSeq], @"since", 
                                                                           [NSNumber numberWithInteger:kPageSize], @"limit", nil];
        
        [couchdb changes:database params:params callback:^(BOOL ok, NSDictionary * data)
        {
            if(ok)
            {
                //NSNumber * lastSeq = [data objectForKey:@"last_seq"];
                //kLastSeq = [lastSeq intValue];
                NSArray * results = [data objectForKey:@"results"];
                
                if([results count] > 0)
                {
                    for(NSDictionary *change in results)
                    {
                        [queue addObject:[change objectForKey:@"id"]];
                    }
                
                    [self next_image];
                }
            }
        }];
    }
    else
    {
        NSLog(@"SLEEP");
        NSNumber * sleep    = [config objectForKey:@"sleep_time"];
        NSTimeInterval time = [sleep integerValue];
        
        [NSTimer scheduledTimerWithTimeInterval:time
                                         target:self 
                                       selector:@selector(sync) 
                                       userInfo:nil 
                                        repeats:NO];
        
    }
}

- (void)next_image
{
    NSString * photoid  = [queue objectAtIndex:0];
    NSString * database = [config valueForKey:@"local_database"];
    
    [couchdb attachment:@"photo.jpg" 
               document:photoid 
               database:database 
               callback:^(BOOL ok, NSDictionary * data){
               
                   [queue removeObjectAtIndex:0];
                   
                   // update our counter
                   kLastSeq = kLastSeq + 1;
                   
                   // if we crash, on restart we know where to begin
                   NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                   [defaults setValue:[NSNumber numberWithInteger:kLastSeq] forKey:@"last_seq"];
                   [defaults synchronize];
                   
                   if(ok)
                   {
                       NSLog(@"Printing Image");
                       NSData * imageData = [data objectForKey:@"data"];
                       [self print_image:imageData];
                   }
                   else
                   {
                       NSLog(@"NO PHOTO!");
                       [self next_image];
                   }
               }];
}

- (void)print_image:(NSData *)data
{
    currentJob = [RLPrintJob printJobWithBluetoothDevice:printer];
    [currentJob retain];
    
    
    [currentJob print:data callback:^
    {
        //[job release];
        [self print_image_complete];
    }];
    
    /*
    IOBluetoothSDPServiceRecord *record;
    OBEXFileTransferServices *transferServices;
    IOBluetoothOBEXSession * OBEXSession;
    
    record = [printer getServiceRecordForUUID:[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassOBEXObjectPush]];
    //mOBEXSession = [IOBluetoothOBEXSession withSDPServiceRecord: record];
    //[mOBEXSession retain];
    OBEXSession = [[IOBluetoothOBEXSession alloc] initWithSDPServiceRecord:record];
    
    // Send the OBEXSession off to FTS
    transferServices = [OBEXFileTransferServices withOBEXSession: OBEXSession];
    
    [transferServices retain];
    [transferServices setDelegate:self];
     */
    
    //Calling this method should trigger the delegate methods sooner or later	
    /*
    if([transferServices connectToObjectPushService] == kOBEXSuccess)
    {
        NSLog(@"ACCEPTS PUSH");
        [transferServices disconnect];
    }*/
    
    //[transferServices connectToObjectPushService]
    
    //NSString * path = [[NSBundle mainBundle] pathForImageResource:@"a31e76d335204ae4bb2b3da5dad69d70_7.jpg"];
    //[mTransferServices sendFile:path];
    //[mTransferServices sendData:data type:@"image/jpeg" name:@"photo.jpg"];
    
    
    
    /*
    NSImage * image = [[NSImage alloc] initWithData:data];
    NSImageView * imageView = [[NSImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 612.0, 612.0)];
    [imageView setImage:image];
    
    NSPrintInfo *info = [NSPrintInfo sharedPrintInfo];
    [info setHorizontalPagination:NSFitPagination];
    [info setVerticalPagination:NSFitPagination];
    [info setHorizontallyCentered:NO];
    [info setVerticallyCentered:NO];
    
    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:imageView printInfo:info];
    [printOp setShowsPrintPanel:NO];
    [printOp setShowsProgressPanel:NO];
    
    [printOp runOperation];
    NSLog(@"Operation Complete");
    
    
    if([queue count] == 0)
    {
        NSLog(@"Sync");
        [self sync];
        return;
    }
    
    //TODO: Need to handle print timing once the printer arrives
    NSLog(@"Next Image");
    [self next_image];
     */
}

- (void)print_image_complete
{
    [currentJob release];
    currentJob = nil;
    
    if([queue count] == 0)
    {
        NSLog(@"Queue is empty, Syncing");
        [self sync];
        return;
    }
    
    NSLog(@"Fetching Next Image");
    [self next_image];
}

- (void)dealloc
{
    [couchdb release];
    [config release];
    [queue release];
    [printer release];
    [super dealloc];
}

@end
