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
        
        if(kLastSeq == 1)
        {
            [self firstrun];   
        }
        else
        {
            [self sync];
        }
    }
    
    return self;
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
            NSNumber * maxSeq = [data objectForKey:@"source_last_seq"];
            kMaxSeq = [maxSeq intValue];
            [self hydrate_queue];
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
    NSLog(@"Printing...");
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
}

- (void)dealloc
{
    [couchdb release];
    [config release];
    [queue release];
    [super dealloc];
}

@end
