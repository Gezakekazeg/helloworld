/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVConfigParser.h"

// The block below is to support NSArray/NSDictionary subscripting in 10.7
#ifdef __MAC_10_7

@interface NSArray(Subscripting)
- (id)objectAtIndexedSubscript:(NSUInteger)index;
@end

@interface NSMutableArray(Subscripting)
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)index;
@end

@interface NSDictionary(Subscripting)
- (id)objectForKeyedSubscript:(id)key;
@end

@interface NSMutableDictionary(Subscripting)
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
@end

#endif

@interface CDVConfigParser ()

@property (nonatomic, readwrite, strong) NSMutableDictionary* pluginsDict;
@property (nonatomic, readwrite, strong) NSMutableDictionary* settings;
@property (nonatomic, readwrite, strong) NSMutableArray* whitelistHosts;
@property (nonatomic, readwrite, strong) NSMutableArray* startupPluginNames;
@property (nonatomic, readwrite, strong) NSString* startPage;

@end

@implementation CDVConfigParser

@synthesize pluginsDict, settings, whitelistHosts, startPage, startupPluginNames;

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.pluginsDict = [[NSMutableDictionary alloc] initWithCapacity:30];
        self.settings = [[NSMutableDictionary alloc] initWithCapacity:30];
        self.whitelistHosts = [[NSMutableArray alloc] initWithCapacity:30];
        self.startupPluginNames = [[NSMutableArray alloc] initWithCapacity:8];
        featureName = nil;
    }
    return self;
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"preference"]) {
        settings[attributeDict[@"name"]] = attributeDict[@"value"];
    } else if ([elementName isEqualToString:@"plugin"]) {
        NSString* name = [attributeDict[@"name"] lowercaseString];
        pluginsDict[name] = attributeDict[@"value"];
        if ([@"true" isEqualToString : attributeDict[@"onload"]]) {
            [self.startupPluginNames addObject:name];
        }
        NSLog(@"\nUse of the <plugin> tag has been deprecated. Use a <feature> tag instead. Change:\n"
            @"    <plugin name=\"%@\" value=\"%@\" />\n"
            @"To:\n"
            @"    <feature name=\"%@\">\n"
            @"        <param name=\"ios-package\" value=\"%@\" />\n"
            @"    </feature>\n"
            , attributeDict[@"name"], attributeDict[@"value"], attributeDict[@"name"], attributeDict[@"value"]);
    } else if ([elementName isEqualToString:@"feature"]) { // store feature name to use with correct parameter set
        featureName = [attributeDict[@"name"] lowercaseString];
    } else if ((featureName != nil) && [elementName isEqualToString:@"param"]) {
        NSString* paramName = [attributeDict[@"name"] lowercaseString];
        id value = attributeDict[@"value"];
        if ([paramName isEqualToString:@"ios-package"]) {
            pluginsDict[featureName] = value;
        }
        if ([paramName isEqualToString:@"onload"] && [@"true" isEqualToString : value]) {
            [self.startupPluginNames addObject:featureName];
        }
    } else if ([elementName isEqualToString:@"access"]) {
        [whitelistHosts addObject:attributeDict[@"origin"]];
    } else if ([elementName isEqualToString:@"content"]) {
        self.startPage = attributeDict[@"src"];
    }
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{
    if ([elementName isEqualToString:@"feature"]) { // no longer handling a feature so release
        featureName = nil;
    }
}

- (void)parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSAssert(NO, @"config.xml parse error line %d col %ld", [parser lineNumber], (long)[parser columnNumber]);
}

@end
