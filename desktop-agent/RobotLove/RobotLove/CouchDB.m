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

#import "CouchDB.h"
#import "ASIHTTPRequest.h"
#import "NSDictionary+UrlEncoding.h"
#import <YAJL/YAJL.h>

static NSString * couchdb_base_url = @"http://127.0.0.1:5984";

@implementation CouchDB

- (id)init
{
    self = [super init];
    
    if (self) 
    {
        // Initialization code here.
    }
    
    return self;
}


- (void)create_database:(NSString *)database callback:(CouchDBCallback)callback
{
    NSString * url = [NSString stringWithFormat:@"%@/%@", couchdb_base_url, database];
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setRequestMethod:@"PUT"];
    
    [request setCompletionBlock:^
    {
        NSString *responseString = [request responseString];
        
        if([responseString rangeOfString:@"error"].location == NSNotFound)
        {
            callback(YES, nil);
            return;
        }
        
        callback(NO, nil);
    }];
    
    [request startAsynchronous];
}

- (void)replicate:(NSString *)from to:(NSString *)to callback:(CouchDBCallback)callback
{
    NSString * url = [NSString stringWithFormat:@"%@/_replicate", couchdb_base_url];
    
    NSDictionary * params = [NSDictionary dictionaryWithObjectsAndKeys:from, @"source", to, @"target", nil];
    NSString * json = [params yajl_JSONString];
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
   
    NSData * data   = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request appendPostData:data];
    [request setRequestMethod:@"POST"];
    
    [request setCompletionBlock:^
     {
         NSDictionary * response = [[request responseData] yajl_JSON];
         BOOL ok = [[response objectForKey:@"ok"] boolValue];
         
         callback(ok, response);
     }];
    
    [request startAsynchronous];
    
}

- (void)changes:(NSString *)database params:(NSDictionary *)params callback:(CouchDBCallback)callback;
{
    NSString * url = [NSString stringWithFormat:@"%@/%@/_changes", couchdb_base_url, database];
    
    if(params != nil)
    {
        NSString * queryString = [params urlEncodedString];
        //NSLog(@"%@", queryString);
        url = [NSString stringWithFormat:@"%@?%@", url, queryString];
    }
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setRequestMethod:@"GET"];
    
    [request setCompletionBlock:^
    {
         NSDictionary * response = [[request responseData] yajl_JSON];
         BOOL ok = YES;
         
         callback(ok, response);
     }];
    
    [request startAsynchronous];
}

- (void)document:(NSString *)document_id database:(NSString *)database callback:(CouchDBCallback)callback
{
    NSString * url = [NSString stringWithFormat:@"%@/%@/%@", couchdb_base_url, database, document_id];
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setRequestMethod:@"GET"];
    
    [request setCompletionBlock:^
     {
         NSDictionary * response = [[request responseData] yajl_JSON];
         BOOL ok = YES;
         
         callback(ok, response);
     }];
    
    [request startAsynchronous];
}

- (void)attachment:(NSString *)filename document:(NSString *)document_id database:(NSString *)database callback:(CouchDBCallback)callback
{
    NSString * url = [NSString stringWithFormat:@"%@/%@/%@/%@", couchdb_base_url, database, document_id, filename];
    
    __block ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setRequestMethod:@"GET"];
    
    [request setCompletionBlock:^
     {
         NSDictionary * response = [NSDictionary dictionaryWithObject:[request responseData] forKey:@"data"];
         
         callback(YES, response);
     }];
    
    [request setFailedBlock:^(void)
    {
        callback(NO, nil);
    }];
    
    [request startAsynchronous];
}

- (void)dealloc
{
    [super dealloc];
}

@end
