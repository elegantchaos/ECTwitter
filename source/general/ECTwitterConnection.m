//
//  ECTwitterConnection.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

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

ECPropertySynthesize(data);
ECPropertySynthesize(identifier);
ECPropertySynthesize(response);

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
    ECPropertyDealloc(data);
    ECPropertyDealloc(identifier);
    ECPropertyDealloc(response);

    [super dealloc];
}


#pragma mark Data helper methods


- (void)resetDataLength
{
    [self.data setLength:0];
}


- (void)appendData:(NSData *)data
{
    [self.data appendData:data];
}


#pragma mark Accessors


- (NSString *)description
{
    NSString *description = [super description];
    
    return [description stringByAppendingFormat:@" (identifier = %@)", _identifier];
}

@end
