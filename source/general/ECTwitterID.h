// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@interface ECTwitterID : NSObject
{
	ECPropertyVariable(string, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(string, NSString*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

+ idFromDictionary: (NSDictionary*) dictionary;

- (id) initWithString: (NSString*) string;

@end
