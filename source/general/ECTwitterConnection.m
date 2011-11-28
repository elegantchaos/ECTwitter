// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterConnection.h"

#import <ECFoundation/NSString+ECCore.h>



@interface NSURLRequest (OAuthExtensions)
-(void)prepare;
@end

@implementation NSURLRequest (OAuthExtensions)


-(void)prepare{
	// do nothing
}

@end



@implementation ECTwitterConnection

@synthesize data;
@synthesize identifier;
@synthesize response;

#pragma mark Initializer


- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	// OAuth requests need to have -prepare called on them first. handle that case before the NSURLConnection sends it
	[request prepare];
	
    if ((self = [super initWithRequest:request delegate:delegate])) 
    {
        self.data = [NSMutableData dataWithCapacity:0];
        self.identifier = [NSString stringWithNewUUID];
    }
    
    return self;
}


- (void)dealloc
{
    [data release];
    [identifier release];
    [response release];

    [super dealloc];
}


#pragma mark Data helper methods


- (void)resetDataLength
{
    [self.data setLength:0];
}


- (void)appendData:(NSData*)dataToAppend
{
    [self.data appendData:dataToAppend];
}


#pragma mark Accessors


- (NSString *)description
{
    NSString *description = [super description];
    
    return [description stringByAppendingFormat:@" (identifier = %@)", self.identifier];
}

@end
