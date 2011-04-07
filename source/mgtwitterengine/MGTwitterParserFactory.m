//
//  MGTwitterEngineParserFactory.m
//
//  Created by Sam Deane on 21/09/2010.
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//

#import "MGTwitterParserFactory.h"

@implementation MGTwitterParserFactory

- (NSString*) APIFormat
{
	NSAssert(NO, @"Parser subclasses should implement this method.");
	return @"";
}

- (void) parseData: (NSData*) data 
			   URL: (NSURL*) URL 
		identifier: (NSString*) identifier 
	   requestType: (MGTwitterRequestType) requestType 
	  responseType: (MGTwitterResponseType) responseType 
			engine: (MGTwitterEngine*) engine
{
	NSAssert(NO, @"Parser subclasses should implement this method.");
}

@end
