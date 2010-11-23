// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class CLLocation;

@interface ECTwitterTweet : NSObject 
{
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(user, NSMutableDictionary*);
	ECPropertyVariable(text, NSString*);
	ECPropertyVariable(source, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(user, NSMutableDictionary*);
ECPropertyDefine(text, NSString*, assign, nonatomic, readonly);
ECPropertyDefine(source, NSString*, assign, nonatomic, readonly);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithDictionary: (NSDictionary*) dictionary;
- (NSString*) description;
- (BOOL) gotLocation;
- (NSString*) locationText;
- (CLLocation*) location;
- (NSDate*) created;
- (NSString*) twitterID;

@end
