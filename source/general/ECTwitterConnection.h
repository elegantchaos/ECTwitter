//
//  MGTwitterHTTPURLConnection.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import <ECFoundation/ECProperties.h>

@interface ECTwitterConnection : NSURLConnection
{
    ECPropertyVariable(data, NSMutableData*);
    ECPropertyVariable(identifier, NSString*);
    ECPropertyVariable(response, NSHTTPURLResponse*);
}

ECPropertyRetained(data, NSMutableData*);
ECPropertyRetained(identifier, NSString*);
ECPropertyRetained(response, NSHTTPURLResponse*);

// Initializer
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;

// Data helper methods
- (void)resetDataLength;
- (void)appendData:(NSData *)data;

@end
