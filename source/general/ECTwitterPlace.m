// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/10/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterPlace.h"

// ==============================================
// Private Methods
// ==============================================

@interface ECTwitterPlace()

@end


@implementation ECTwitterPlace

// ==============================================
// Log Channels
// ==============================================

ECDefineDebugChannel(TwitterPlaceChannel);

// ==============================================
// Properties
// ==============================================

ECPropertySynthesize(data);
ECPropertySynthesize(containers);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithPlaceInfo: (NSDictionary*) dictionary
{
	if ((self = [super init]) != nil)
	{
		self.data = dictionary;
		
		NSMutableArray* containers = [[NSMutableArray alloc] init];
		NSArray* containersInfo = [dictionary objectForKey: @"contained_within"];
		for (NSDictionary* containerInfo in containersInfo)
		{
			ECTwitterPlace* place = [[ECTwitterPlace alloc] initWithPlaceInfo: containerInfo];
			[containers addObject: place];
			[place release];
		}
		self.containers = containers;
		[containers release];
		
		ECDebug(TwitterPlaceChannel, @"made place: %@", self.name);
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(data);
	ECPropertyDealloc(containers);

	[super dealloc];
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

- (NSString*) type
{
	return [self.data objectForKey: @"place_type"];
}

@end
