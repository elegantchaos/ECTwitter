//
//  MGTwitterEngineDelegate.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 17/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

typedef enum _MGTwitterRequestType {
	MGTwitterGenericRequest,				// explicit request to parse the results generically
	MGTwitterOAuthTokenRequest,				// asking for an authorisation token
} MGTwitterRequestType;

typedef enum _MGTwitterResponseType {
    MGTwitterStatuses           = 0,    // one or more statuses
    MGTwitterStatus             = 1,    // exactly one status
    MGTwitterUsers              = 2,    // one or more user's information
    MGTwitterUser               = 3,    // info for exactly one user
    MGTwitterDirectMessages     = 4,    // one or more direct messages
    MGTwitterDirectMessage      = 5,    // exactly one direct message
    MGTwitterGenericUnparsed    = 6,    // a generic response not requiring parsing
	MGTwitterMiscellaneous		= 8,	// a miscellaneous response of key-value pairs
    MGTwitterImage              = 7,    // an image
	MGTwitterSearchResults		= 9,	// search results
	MGTwitterSocialGraph		= 10,
	MGTwitterOAuthToken         = 11,
	MGTwitterUserLists          = 12,
	MGTwitterGenericParsed		= 13,	// results from the generic parser
} MGTwitterResponseType;

// This key is added to each tweet or direct message returned,
// with an NSNumber value containing an MGTwitterRequestType.
// This is designed to help client applications aggregate updates.
#define TWITTER_SOURCE_REQUEST_TYPE @"source_api_request_type"
