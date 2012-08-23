// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class ECTwitterTweet;
@class ECTwitterHandler;
@class ECTwitterUser;

typedef enum
{
    MethodMentions,
    MethodHome,
    MethodTimeline
} FetchMethod;

typedef enum 
{
    FetchLatest,
    FetchOlder
} FetchType;

@interface ECTwitterTimeline : ECTwitterCachedObject 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) NSMutableArray* tweets;
@property (nonatomic, retain) ECTwitterTweet* oldestTweet;
@property (nonatomic, retain) ECTwitterTweet* newestTweet;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)initWithCache:(ECTwitterCache *)cache;
- (id)initWithCoder:(NSCoder*)coder;
- (void)encodeWithCoder:(NSCoder*)coder;
- (void)refresh;
- (void) addTweet:(ECTwitterTweet*)tweet;
- (ECTwitterTimeline*)sortedWithSelector:(SEL) selector;
- (void)timelineHandler:(ECTwitterHandler*)handler;
- (void)fetchTweetsForUser:(ECTwitterUser*)user method:(FetchMethod)method type:(FetchType)type;
- (NSUInteger)count;
- (void)removeMissingTweets;

@end
