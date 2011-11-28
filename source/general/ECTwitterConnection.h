//
//  MGTwitterHTTPURLConnection.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

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
