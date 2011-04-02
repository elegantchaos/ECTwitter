// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterID.h"


// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterID()

@end


@implementation ECTwitterID

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(string);

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Methods
// --------------------------------------------------------------------------

+ (ECTwitterID*) idFromDictionary:(NSDictionary *)dictionary
{
	NSString* string = [dictionary objectForKey: @"id_str"];
	ECTwitterID* newID = [[ECTwitterID alloc] initWithString: string];
	return [newID autorelease];
}

- (id) initWithString: (NSString*) string
{
	if ((self = [super init]) != nil)
	{
		self.string = string;
	}
	
	return self;
}

- (void) dealloc
{
	ECPropertyDealloc(string);
	
	[super dealloc];
}

// --------------------------------------------------------------------------
//! Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*) description
{
	return self.string;
}

@end
