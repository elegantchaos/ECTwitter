// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 24/11/2010
//
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@interface ECTwitterConnection : NSURLConnection

@property (strong, nonatomic) NSMutableData* data;
@property (strong, nonatomic) NSString* identifier;
@property (strong, nonatomic) NSHTTPURLResponse* response;

// Initializer
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;

// Data helper methods
- (void)resetDataLength;
- (void)appendData:(NSData *)data;

@end
