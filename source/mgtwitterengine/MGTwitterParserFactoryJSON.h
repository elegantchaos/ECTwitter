//
//  MGTwitterParserFactoryJSON.h
//
//  Created by Sam Deane on 21/09/2010.
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//

#import "MGTwitterParserFactory.h"
#import "MGTwitterEngineDelegate.h"

// --------------------------------------------------------------------------
//! Abstract base class for all JSON based parsers.
//!
//! The JSON based parsers support delivery of results one
//! at a time via the receivedObject: method, or all together
//! via the normal delegate methods.
//! 
//! This behaviour can be set with the deliveryOptions property.
//! The default behaviour is MGTwitterEngineDeliveryAllResultsOption.
// --------------------------------------------------------------------------

@interface MGTwitterParserFactoryJSON : MGTwitterParserFactory 
{
	MGTwitterEngineDeliveryOptions _deliveryOptions;	
}

// --------------------------------------------------------------------------
//! Returns @"json" to indicate that we want JSON data.
// --------------------------------------------------------------------------

- (NSString*) APIFormat;

// --------------------------------------------------------------------------
//! Return the current delivery options for the parser.
// --------------------------------------------------------------------------

- (MGTwitterEngineDeliveryOptions)deliveryOptions;

// --------------------------------------------------------------------------
//! Set the delivery options for the parser.
// --------------------------------------------------------------------------

- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;

@end
