// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUserList.h"
#import "ECTwitterUser.h"

// ==============================================
// Private Methods
// ==============================================

#pragma mark -
#pragma mark Private Methods

@interface ECTwitterUserList()

@end


@implementation ECTwitterUserList

// ==============================================
// Properties
// ==============================================

#pragma mark -
#pragma mark Properties

ECPropertySynthesize(users);

// ==============================================
// Constants
// ==============================================

#pragma mark -
#pragma mark Constants

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Methods

// --------------------------------------------------------------------------
//! Set up the object.
// --------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]) != nil)
	{
		
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(users);
	
	[super dealloc];
}


// --------------------------------------------------------------------------
//! Add a tweet to our timeline.
// --------------------------------------------------------------------------

- (void) addUser: (ECTwitterUser*) user;
{
	NSMutableArray* users = self.users;
	if (!users)
	{
		users = [[NSMutableArray alloc] initWithCapacity: 1];
		self.users = users;
		[users release];
	}
	
	if ([users indexOfObject: user] == NSNotFound)
	{
		[users addObject: user];
	}
}

// --------------------------------------------------------------------------
//! Return a new, sorted version of this timeline.
// --------------------------------------------------------------------------

- (ECTwitterUserList*)	sortedWithSelector: (SEL) selector
{
	ECTwitterUserList* userList = [[ECTwitterUserList alloc] init];
    NSMutableArray* usersCopy = [self.users mutableCopy];
	userList.users = usersCopy;
	[userList.users sortUsingSelector: selector];
    [usersCopy release];
	
	return [userList autorelease];
}

@end
