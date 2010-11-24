// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class ECTwitterID;

@interface ECTwitterUser : NSObject 
{
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(twitterID, ECTwitterID*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithUserInfo: (NSDictionary*) info;
- (void) refreshWithInfo: (NSDictionary*) info;
- (NSString*) description;
- (NSString*) name;
- (NSString*) twitterName;

@end
