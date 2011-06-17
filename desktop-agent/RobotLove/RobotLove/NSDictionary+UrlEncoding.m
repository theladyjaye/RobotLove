
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

#import "NSDictionary+UrlEncoding.h"


// http://splinter.com.au/build-a-url-query-string-in-obj-c-from-a-dict
static NSString * urlEscape(NSString *unencodedString)
{
	NSString *s  = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                      (CFStringRef)unencodedString,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                      kCFStringEncodingUTF8);
	return [s autorelease];
}

// http://stackoverflow.com/questions/718429/creating-url-query-parameters-from-nsdictionary-objects-in-objectivec
@implementation NSDictionary(UrlEncoding)

-(NSString *) urlEncodedString 
{
    NSMutableArray *parts = [NSMutableArray array];
    
    for (id key in self) 
    {
        id value = [self objectForKey: key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", urlEscape([key description]), urlEscape([value description])];
        
        [parts addObject: part];
    }
    
    return [parts componentsJoinedByString: @"&"];
}


@end
