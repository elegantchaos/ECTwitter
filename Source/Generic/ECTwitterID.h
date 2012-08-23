// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@interface ECTwitterID : NSObject

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) NSString* string;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

+ (ECTwitterID*)idFromKey:(NSString*)key dictionary:(NSDictionary*)dictionary;
+ (ECTwitterID*)idFromDictionary:(NSDictionary*)dictionary;
+ (ECTwitterID*)idFromString:(NSString*)string;

- (id) initWithString:(NSString*)string;

@end
