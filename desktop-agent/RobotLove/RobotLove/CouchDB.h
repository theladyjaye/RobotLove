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

#import <Foundation/Foundation.h>

typedef void (^CouchDBCallback)(BOOL, NSDictionary *);

@interface CouchDB : NSObject {
@private
    
}
- (void)create_database:(NSString *)database callback:(CouchDBCallback)callback;
- (void)replicate:(NSString *)from to:(NSString *)to callback:(CouchDBCallback)callback;
- (void)changes:(NSString *)database params:(NSDictionary *)params callback:(CouchDBCallback)callback;
- (void)document:(NSString *)document_id database:(NSString *)database callback:(CouchDBCallback)callback;
- (void)attachment:(NSString *)filename document:(NSString *)document_id database:(NSString *)database callback:(CouchDBCallback)callback;
@end
