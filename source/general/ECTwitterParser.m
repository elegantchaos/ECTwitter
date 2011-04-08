// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 08/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterParser.h"

#include <yajl/yajl_parse.h>

@interface ECTwitterParser()

ECPropertyRetained(currentDictionary, NSMutableDictionary*);
ECPropertyRetained(currentArray, NSMutableArray*);
ECPropertyRetained(currentKey, NSString*);
ECPropertyRetained(identifier, NSString*);
ECPropertyRetained(parsedObjects, NSMutableArray*);
ECPropertyRetained(stack, NSMutableArray*);

- (void)parseSimpleData:(NSData*)data;
- (void)parseJSONData:(NSData*)data;

- (void)addValue:(id)value;

- (void)parsedObject:(NSDictionary *)dictionary;


@end

@implementation ECTwitterParser

// --------------------------------------------------------------------------
#pragma mark - Debug Channels
// --------------------------------------------------------------------------

ECDefineDebugChannel(MGTwitterEngineParsingChannel);


// --------------------------------------------------------------------------
#pragma mark - Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(currentDictionary);
ECPropertySynthesize(currentArray);
ECPropertySynthesize(currentKey);
ECPropertySynthesize(identifier);
ECPropertySynthesize(parsedObjects);
ECPropertySynthesize(stack);

// --------------------------------------------------------------------------
#pragma mark - Prototypes
// --------------------------------------------------------------------------

int process_yajl_null(void *ctx);
int process_yajl_boolean(void * ctx, int boolVal);
int process_yajl_number(void *ctx, const char *numberVal, unsigned int numberLen);
int process_yajl_string(void *ctx, const unsigned char * stringVal, unsigned int stringLen);
int process_yajl_map_key(void *ctx, const unsigned char * stringVal, unsigned int stringLen);
int process_yajl_start_map(void *ctx);
int process_yajl_end_map(void *ctx);
int process_yajl_start_array(void *ctx);
int process_yajl_end_array(void *ctx);

// --------------------------------------------------------------------------
#pragma mark - Globals
// --------------------------------------------------------------------------

static yajl_callbacks callbacks = {
	process_yajl_null,
	process_yajl_boolean,
	NULL,
	NULL,
	process_yajl_number,
	process_yajl_string,
	process_yajl_start_map,
	process_yajl_map_key,
	process_yajl_end_map,
	process_yajl_start_array,
	process_yajl_end_array
};


#pragma mark - Lifecycle

// --------------------------------------------------------------------------
//! Setup parser.
// --------------------------------------------------------------------------

- (id)initWithDelegate:(id<MGTwitterEngineDelegate>)delegate options:(MGTwitterEngineDeliveryOptions)options
{
	if ((self = [super init]) != nil)
	{
		mOptions = options;
		mDelegate = delegate;
    }
    
    return self;
}

// --------------------------------------------------------------------------
//! Cleanup.
// --------------------------------------------------------------------------

- (void)dealloc
{
    ECPropertyDealloc(currentDictionary);
    ECPropertyDealloc(currentArray);
    ECPropertyDealloc(currentKey);
    ECPropertyDealloc(identifier);
    ECPropertyDealloc(parsedObjects);
    ECPropertyDealloc(stack);
	
	mDelegate = nil;
	[super dealloc];
}

#pragma mark - Parsing

// --------------------------------------------------------------------------
//! Parse some data.
// --------------------------------------------------------------------------

- (void)parseData:(NSData*)data identifier:(NSString*)identifier
{
    self.identifier = identifier;
    
    if (mOptions & MGTwitterEngineDeliveryAllResultsOption)
    {
        self.parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    if ([data length] <= 5)
    {
        [self parseSimpleData:data];
    }
    else
    {
        [self parseJSONData:data];
    }
    
    // notify the delegate that parsing completed
    [mDelegate genericResultsReceived:self.parsedObjects forRequest:self.identifier];
}

// --------------------------------------------------------------------------
//! Parse simple stuff that isn't legal JSON.
// --------------------------------------------------------------------------

- (void)parseSimpleData:(NSData*)data
{
    // NOTE: this is a hack for API methods that return short JSON responses that can't be parsed by YAJL. These include:
    //   friendships/exists: returns "true" or "false"
    //   help/test: returns "ok"
    // An empty response of "[]" is a special case.
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (! [jsonString isEqualToString:@"[]"])
    {
        NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
        
        if ([jsonString isEqualToString:@"\"ok\""])
        {
            [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"ok"];
        }
        else
        {
            [dictionary setObject:[NSNumber numberWithBool:[jsonString isEqualToString:@"true"]] forKey:@"friends"];
        }
        
        [self parsedObject:dictionary];
    }
    [jsonString release];
    
}

// --------------------------------------------------------------------------
//! Parse proper JSON.
// --------------------------------------------------------------------------

- (void)parseJSONData:(NSData*)data
{
    self.stack = [NSMutableArray array];
    
    // setup the yajl parser
    yajl_parser_config cfg = {
        0, // allowComments: if nonzero, javascript style comments will be allowed in the input (both /* */ and //)
        0  // checkUTF8: if nonzero, invalid UTF8 strings will cause a parse error
    };
    yajl_handle handle = yajl_alloc(&callbacks, &cfg, NULL, self);
    if (handle)
    {
        yajl_status status = yajl_parse(handle, [data bytes], (unsigned int) [data length]);
        if (status != yajl_status_insufficient_data && status != yajl_status_ok)
        {
            unsigned char *errorMessage = yajl_get_error(handle, 0, [data bytes], (unsigned int) [data length]);
            ECDebug(MGTwitterEngineParsingChannel, @"MGTwitterYAJLParser: error = %s", errorMessage);
            NSError* error = [NSError errorWithDomain:@"YAJL" code:status userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:(char *)errorMessage] forKey:@"errorMessage"]];
            [mDelegate requestFailed:self.identifier withError:error];
            yajl_free_error(handle, errorMessage);
        }
        
        // free the yajl parser
        yajl_free(handle);
    }
    
    self.stack = nil;
    self.currentDictionary = nil;
    self.currentArray = nil;
}

#pragma mark - Parsing Stack

// --------------------------------------------------------------------------
//! Push current collection onto the stack.
//! Also saves the current key on the stack.
// --------------------------------------------------------------------------

- (void)pushStack
{
    id objectToPush = self.currentArray;
    if (!objectToPush)
    {
        objectToPush = self.currentDictionary;
    }
    
    if (objectToPush)
    {
        NSString* key = self.currentKey;
        [self.stack addObject:key ? key : @""];
        [self.stack addObject:objectToPush];
    }
}

// --------------------------------------------------------------------------
//! Pop collection from the stack.
//! Also restores the value of the current key at the point that the collection was pushed.
// --------------------------------------------------------------------------

- (void)popStack
{
    self.currentDictionary = nil;
    self.currentArray = nil;
    NSUInteger stackLevel = [self.stack count];
	if (stackLevel > 1)
    {
        id popped = [self.stack lastObject];
        [self.stack removeLastObject];
        self.currentKey = [self.stack lastObject];
        [self.stack removeLastObject];
        
        // still stuff on the stack, so restore the popped object as the current context
        ECDebug(MGTwitterEngineParsingChannel, @"popped %@", [popped class]);
        if ([popped isKindOfClass:[NSMutableArray class]])
        {
            ECDebug(MGTwitterEngineParsingChannel, @"popped array with key %@", self.currentKey);
            self.currentArray = popped;
        }
        else
        {
            ECDebug(MGTwitterEngineParsingChannel, @"popped dictionary with key %@", self.currentKey);
            self.currentDictionary = popped;
        }
    }
}

#pragma mark - Parser Support

// --------------------------------------------------------------------------
//! Add a value to the current collection.
// --------------------------------------------------------------------------

- (void)addValue:(id)value
{
    
    if (self.currentArray)
    {
        ECDebug(MGTwitterEngineParsingChannel, @"added item: %@ (%@) to array", value, [value class]);
        [self.currentArray addObject:value];
    }
    else if (self.currentDictionary)
    {
        if (self.currentKey == nil)
        {
            ECDebug(MGTwitterEngineParsingChannel, @"added item: %@ (%@) with nil key", value, [value class]);
        }

        else if (value == nil)
        {
            ECDebug(MGTwitterEngineParsingChannel, @"added nil item with key %@", self.currentKey);
        }
        
        ECDebug(MGTwitterEngineParsingChannel, @"added item: %@ (%@) to dictionary as key %@", value, [value class], self.currentKey);
        [self.currentDictionary setObject:value forKey:self.currentKey];
    }
	else
    {
        ECDebug(MGTwitterEngineParsingChannel, @"root item: %@ (%@)", value, [value class]);
        [self parsedObject:value];
    }
    self.currentKey = nil;
}

#pragma mark Delegate callbacks

- (void)parsedObject:(NSDictionary *)dictionary
{
	if (mOptions & MGTwitterEngineDeliveryIndividualResultsOption)
    {
        [mDelegate receivedObject:dictionary forRequest:self.identifier];
    }
    else
    {
        [self.parsedObjects addObject:dictionary];
    }
}

#pragma mark - YAJL Callbacks

int process_yajl_null(void *ctx)
{
	ECTwitterParser* self = ctx;
    [self addValue:[NSNull null]];
	
    return 1;
}

int process_yajl_boolean(void * ctx, int boolVal)
{
	ECTwitterParser* self = ctx;
    [self addValue:[NSNumber numberWithBool:(BOOL)boolVal]];
    
    return 1;
}

int process_yajl_number(void *ctx, const char *numberVal, unsigned int numberLen)
{
	ECTwitterParser* self = ctx;
    NSString *stringValue = [[NSString alloc] initWithBytesNoCopy:(void *)numberVal length:numberLen encoding:NSUTF8StringEncoding freeWhenDone:NO];
    
    // if there's a decimal, assume it's a double
    if([stringValue rangeOfString:@"."].location != NSNotFound)
    {
        NSNumber *doubleValue = [NSNumber numberWithDouble:[stringValue doubleValue]];
        [self addValue:doubleValue];
    }
    else
    {
        NSNumber *longLongValue = [NSNumber numberWithLongLong:[stringValue longLongValue]];
        [self addValue:longLongValue];
    }
    
    [stringValue release];
	
	return 1;
}

int process_yajl_string(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	ECTwitterParser* parser = ctx;
	
    NSMutableString *value = [[[NSMutableString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease];
    
    [value replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    [value replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    [value replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    [value replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    
    if ([parser.currentKey isEqualToString:@"created_at"])
    {
        // we have a priori knowledge that the value for created_at is a date, not a string
        struct tm theTime;
        if ([value hasSuffix:@"+0000"])
        {
            // format for Search API: "Fri, 06 Feb 2009 07:28:06 +0000"
            strptime([value UTF8String], "%a, %d %b %Y %H:%M:%S +0000", &theTime);
        }
        else
        {
            // format for REST API: "Thu Jan 15 02:04:38 +0000 2009"
            strptime([value UTF8String], "%a %b %d %H:%M:%S +0000 %Y", &theTime);
        }
        time_t epochTime = timegm(&theTime);
        // save the date as a long with the number of seconds since the epoch in 1970
        [parser addValue:[NSNumber numberWithLong:epochTime]];
        // this value can be converted to a date with [NSDate dateWithTimeIntervalSince1970:epochTime]
    }
    else
    {
        [parser addValue:value];
    }
    
    return 1;
}

int process_yajl_map_key(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	ECTwitterParser* parser = ctx;
	parser.currentKey = [[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding];
    
    return 1;
}

int process_yajl_start_map(void *ctx)
{
	ECTwitterParser* parser = ctx;
	ECDebug(MGTwitterEngineParsingChannel, @"dictionary start");
	
	NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    [parser pushStack];
    parser.currentDictionary = newDictionary;
    parser.currentArray = nil;    
    
	return 1;
}


int process_yajl_end_map(void *ctx)
{
	ECTwitterParser* parser = ctx;
	ECDebug(MGTwitterEngineParsingChannel, @"dictionary end %@", parser.currentDictionary);
	
    NSMutableDictionary* dictionary = parser.currentDictionary;
    [parser popStack];
    [parser addValue:dictionary];
    
	return 1;
}

int process_yajl_start_array(void *ctx)
{
	ECTwitterParser* parser = ctx;
	ECDebug(MGTwitterEngineParsingChannel, @"array start");

	
	NSMutableArray* newArray = [NSMutableArray array];
    [parser pushStack];
    parser.currentDictionary = nil;
    parser.currentArray = newArray;
	
    return 1;
}

int process_yajl_end_array(void *ctx)
{
	ECTwitterParser* parser = ctx;
	ECDebug(MGTwitterEngineParsingChannel, @"array end %@", parser.currentArray);
	
    NSMutableArray* array = parser.currentArray;
    [parser popStack];
    [parser addValue:array];
	
    return 1;
}

@end
