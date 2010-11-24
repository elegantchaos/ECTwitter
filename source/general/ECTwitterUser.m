// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUser.h"
#import "ECTwitterID.h"

@implementation ECTwitterUser

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(data);
ECPropertySynthesize(twitterID);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithUserInfo: (NSDictionary*) dictionary
{
	if ((self = [super init]) != nil)
	{
		self.data = dictionary;
		self.twitterID = [ECTwitterID idFromDictionary: dictionary];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up with just an ID.
// --------------------------------------------------------------------------

- (id) initWithID: (ECTwitterID*) twitterID
{
	if ((self = [super init]) != nil)
	{
		self.twitterID = twitterID;
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(data);
	ECPropertyDealloc(twitterID);

	[super dealloc];
}

// --------------------------------------------------------------------------
//! Update with new info
// --------------------------------------------------------------------------

- (void) refreshWithInfo: (NSDictionary*) info
{
	self.data = info;
}

// --------------------------------------------------------------------------
//! Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*) description
{
	return [self.data description];
}

// --------------------------------------------------------------------------
//! Return the proper name of the user.
// --------------------------------------------------------------------------

- (NSString*) name
{
	return [self.data objectForKey: @"name"];
}

// --------------------------------------------------------------------------
//! Return the twitter name of the user.
// --------------------------------------------------------------------------

- (NSString*) twitterName
{
	return [self.data objectForKey: @"screen_name"];
}

// --------------------------------------------------------------------------
//! Return the persistent twitter id of the user.
// --------------------------------------------------------------------------

- (ECTwitterID*) twitterID
{
	return [self.data objectForKey: @"id_str"];
}

@end
