// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 05/08/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class CLLocation;
@class ECTwitterID;
@class ECTwitterUser;

@interface ECTwitterTweet : ECTwitterCachedObject 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, readonly) NSString* text;
@property (strong, nonatomic) NSDictionary* data;
@property (strong, nonatomic) ECTwitterID* twitterID;
@property (strong, nonatomic) ECTwitterID* authorID;
@property (strong, nonatomic) ECTwitterUser* cachedAuthor;
@property (nonatomic, assign) NSUInteger viewed;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithInfo:(NSDictionary*)info inCache:(ECTwitterCache*)cache;
- (id)				initWithID:(ECTwitterID*)tweetID inCache:(ECTwitterCache*)cache;
- (id)              initWithCoder:(NSCoder*)coder;

- (BOOL)			gotData;

- (void)			refreshWithInfo:(NSDictionary*)info;

- (NSString*)		description;
- (BOOL)			gotLocation;
//- (NSString*)locationText;
- (CLLocation*)		location;
- (NSDate*)			created;
- (ECTwitterUser*)	author;
- (ECTwitterID*)	authorID;
- (BOOL)			isFavourited;
- (BOOL)			mentionsUser:(ECTwitterUser*)user;

- (NSString*)		inReplyToTwitterName;
- (ECTwitterID*)	inReplyToMessageID;
- (ECTwitterID*)	inReplyToAuthorID;

- (NSString*)		sourceName;
- (NSURL*)			sourceURL;

- (NSComparisonResult) compareByDateAscending:(ECTwitterTweet*)other;
- (NSComparisonResult) compareByDateDescending:(ECTwitterTweet*)other;
- (NSComparisonResult) compareByViewsDateDescending:(ECTwitterTweet*)other;

@end


// --------------------------------------------------------------------------
// Public Constants
// --------------------------------------------------------------------------

static const NSInteger kTweetCharacterLimit = 140;
