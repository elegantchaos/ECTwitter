// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@interface ECTwitterConnection : NSURLConnection

@property (nonatomic, retain) NSMutableData* data;
@property (nonatomic, retain) NSString* identifier;
@property (nonatomic, retain) NSHTTPURLResponse* response;

// Initializer
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;

// Data helper methods
- (void)resetDataLength;
- (void)appendData:(NSData *)data;

@end
