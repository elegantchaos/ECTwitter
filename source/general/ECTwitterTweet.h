// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class CLLocation;
@class ECTwitterID;

@interface ECTwitterTweet : NSObject 
{
	ECPropertyVariable(twitterID, ECTwitterID*);
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(user, NSMutableDictionary*);
	ECPropertyVariable(text, NSString*);
	ECPropertyVariable(source, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyDefine(source, NSString*, assign, nonatomic, readonly);
ECPropertyDefine(text, NSString*, assign, nonatomic, readonly);
ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);
ECPropertyRetained(user, NSMutableDictionary*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithDictionary: (NSDictionary*) dictionary;
- (id) initWithID: (ECTwitterID*) tweetID;
- (NSString*) description;
- (BOOL) gotLocation;
- (NSString*) locationText;
- (CLLocation*) location;
- (NSDate*) created;
- (ECTwitterID*) authorID;
@end
