// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

@synthesize string;

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Methods
// --------------------------------------------------------------------------

+ (ECTwitterID*)idFromString:(NSString *)string
{
    ECTwitterID* result = [[ECTwitterID alloc] initWithString: string];
	return [result autorelease];
}

+ (ECTwitterID*)idFromKey:(NSString *)key dictionary:(NSDictionary *)dictionary
{
	NSString* string = [dictionary objectForKey: key];
    return [self idFromString:string];
}

+ (ECTwitterID*)idFromDictionary:(NSDictionary *)dictionary
{
    return [self idFromKey:@"id_str" dictionary:dictionary];
}

- (id) initWithString:(NSString*)stringIn
{
    if (stringIn == nil)
    {
        NSLog(@"nil string detected");
    }
    ECAssertNonNil(stringIn);

	if ((self = [super init]) != nil)
	{
		self.string = stringIn;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super init]) != nil)
    {
        self.string = [coder decodeObjectForKey:@"id"];
    }
    
    ECAssertNonNil(self.string);
    
    return self;
}

- (void) dealloc
{
	[string release];
	
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    ECAssertNonNil(self.string);
    [coder encodeObject:self.string forKey:@"id"];
}

// --------------------------------------------------------------------------
//! Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*)description
{
	return self.string;
}

@end
