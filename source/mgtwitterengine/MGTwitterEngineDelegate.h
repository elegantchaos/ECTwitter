//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 16/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

typedef enum _MGTwitterEngineDeliveryOptions {
	// all results will be delivered as an array via statusesReceived: and similar delegate methods
    MGTwitterEngineDeliveryAllResultsOption = 1 << 0,

	// individual results will be delivered as a dictionary via the receivedObject: delegate method
    MGTwitterEngineDeliveryIndividualResultsOption = 1 << 1,
	
	// these options can be combined with the | operator
} MGTwitterEngineDeliveryOptions;



@protocol MGTwitterEngineDelegate

// These delegate methods are called after a connection has been established
- (void)requestSucceeded:(NSString *)connectionIdentifier;
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error;

@optional

// This delegate method is called each time a new result is parsed from the connection and
// the deliveryOption is configured for MGTwitterEngineDeliveryIndividualResults.
- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier;

// These delegate methods are called after all results are parsed from the connection. If 
// the deliveryOption is configured for MGTwitterEngineDeliveryAllResults (the default), a
// collection of all results is also returned.
- (void)genericResultsReceived:(NSArray*)genericResults forRequest:(NSString *)connectionIdentifier;

// This delegate method is called whenever a connection has finished.
- (void)connectionStarted:(NSString *)connectionIdentifier;
- (void)connectionFinished:(NSString *)connectionIdentifier;

@end
