// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 05/10/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

@synthesize data;
@synthesize containers;

// --------------------------------------------------------------------------
/// Set up with data properties.
// --------------------------------------------------------------------------

- (id)initWithPlaceInfo:(NSDictionary*)dictionary
{
	if ((self = [super init]) != nil)
	{
		self.data = dictionary;
		
		NSMutableArray* newContainers = [[NSMutableArray alloc] init];
		NSArray* containersInfo = [dictionary objectForKey: @"contained_within"];
		for (NSDictionary* containerInfo in containersInfo)
		{
			ECTwitterPlace* place = [[ECTwitterPlace alloc] initWithPlaceInfo: containerInfo];
			[newContainers addObject: place];
			[place release];
		}
		self.containers = newContainers;
		[newContainers release];
		
		ECDebug(TwitterPlaceChannel, @"made place: %@", self.name);
	}
	
	return self;
}

// --------------------------------------------------------------------------
/// Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	[data release];
	[containers release];

	[super dealloc];
}

// --------------------------------------------------------------------------
/// Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*)description
{
	return [self.data description];
}

// --------------------------------------------------------------------------
/// Return the proper name of the user.
// --------------------------------------------------------------------------

- (NSString*)name
{
	return [self.data objectForKey: @"name"];
}

// --------------------------------------------------------------------------
/// Return the twitter name of the user.
// --------------------------------------------------------------------------

- (NSString*)type
{
	return [self.data objectForKey: @"place_type"];
}

@end
