//
//  MGTwitterParserFactoryYAJLGeneric.m
//
//  Created by Sam Deane on 21/09/2010.
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//

#import "MGTwitterParserFactoryYAJLGeneric.h"
#import "MGTwitterEngine.h"
#import "MGTwitterYAJLGenericParser.h"
#import "OAuthConsumer.h"

@implementation MGTwitterParserFactoryYAJLGeneric

- (void) parseData: (NSData*) data URL: (NSURL*) URL identifier: (NSString*) identifier engine: (MGTwitterEngine*) engine
{
    // responseType is ignored - we always use the same parser
    
    [MGTwitterYAJLGenericParser 
     parserWithJSON:data 
     delegate:engine 
     connectionIdentifier:identifier
     URL:URL
     deliveryOptions:_deliveryOptions];

}

@end
