//
//  MGTwitterParserDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

@protocol MGTwitterParserDelegate
 
- (void)parsingSucceededForRequest:(NSString *)identifier withParsedObjects:(NSArray *)parsedObjects;

- (void)parsingFailedForRequest:(NSString *)requestIdentifier withError:(NSError *)error;

@optional

- (void)parsedObject:(NSDictionary *)parsedObject forRequest:(NSString *)identifier;

@end
