//
//  MGTwitterYAJLGenericParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.

#import "MGTwitterYAJLGenericParser.h"
#import "MGTwitterLogging.h"

@interface MGTwitterYAJLGenericParser()

@property (nonatomic, retain) NSMutableArray* stack;
@property (nonatomic, retain) NSMutableDictionary* currentDictionary;
@property (nonatomic, retain) NSMutableArray* currentArray;
@property (nonatomic, retain) NSString* currentKey;

- (void)addValue:(id)value;
- (void)startDictionary;
- (void)endDictionary;
- (void)startArray;
- (void)endArray;

// delegate callbacks
- (void)_parsingDidEnd;
- (void)_parsingErrorOccurred:(NSError *)parseError;
- (void)_parsedObject:(NSDictionary *)dictionary;


@end

@implementation MGTwitterYAJLGenericParser

@synthesize stack;
@synthesize currentDictionary;
@synthesize currentArray;
@synthesize currentKey;

// prototypes
int process_yajl_null(void *ctx);
int process_yajl_boolean(void * ctx, int boolVal);
int process_yajl_number(void *ctx, const char *numberVal, unsigned int numberLen);
int process_yajl_string(void *ctx, const unsigned char * stringVal, unsigned int stringLen);
int process_yajl_map_key(void *ctx, const unsigned char * stringVal, unsigned int stringLen);
int process_yajl_start_map(void *ctx);
int process_yajl_end_map(void *ctx);
int process_yajl_start_array(void *ctx);
int process_yajl_end_array(void *ctx);

#pragma mark Callbacks

int process_yajl_null(void *ctx)
{
	MGTwitterYAJLGenericParser* self = ctx;
    [self addValue:[NSNull null]];
	
    return 1;
}

int process_yajl_boolean(void * ctx, int boolVal)
{
	MGTwitterYAJLGenericParser* self = ctx;
    [self addValue:[NSNumber numberWithBool:(BOOL)boolVal]];

    return 1;
}

int process_yajl_number(void *ctx, const char *numberVal, unsigned int numberLen)
{
	MGTwitterYAJLGenericParser* self = ctx;
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
	MGTwitterYAJLGenericParser* self = ctx;
	
    NSMutableString *value = [[[NSMutableString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding] autorelease];
    
    [value replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    [value replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    [value replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
    [value replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];

    if ([self.currentKey isEqualToString:@"created_at"])
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
        [self addValue:[NSNumber numberWithLong:epochTime]];
        // this value can be converted to a date with [NSDate dateWithTimeIntervalSince1970:epochTime]
    }
    else
    {
        [self addValue:value];
    }

    return 1;
}

int process_yajl_map_key(void *ctx, const unsigned char * stringVal, unsigned int stringLen)
{
	MGTwitterYAJLGenericParser* self = ctx;
	self.currentKey = [[NSString alloc] initWithBytes:stringVal length:stringLen encoding:NSUTF8StringEncoding];

    return 1;
}

int process_yajl_start_map(void *ctx)
{
	MGTwitterYAJLGenericParser* self = ctx;
	
	[self startDictionary];

	return 1;
}


int process_yajl_end_map(void *ctx)
{
	MGTwitterYAJLGenericParser* self = ctx;
	
	[self endDictionary];

	return 1;
}

int process_yajl_start_array(void *ctx)
{
	MGTwitterYAJLGenericParser* self = ctx;
	
	[self startArray];
	
    return 1;
}

int process_yajl_end_array(void *ctx)
{
	MGTwitterYAJLGenericParser* self = ctx;
	
	[self endArray];
	
    return 1;
}

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

#pragma mark Creation and Destruction


+ (id)parserWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
	connectionIdentifier:(NSString *)identifier URL:(NSURL *)URL deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions
{
	id parser = [[self alloc] initWithJSON:theJSON 
			delegate:theDelegate 
			connectionIdentifier:identifier 
			URL:URL
			deliveryOptions:deliveryOptions];

	return [parser autorelease];
}


- (id)initWithJSON:(NSData *)theJSON delegate:(NSObject *)theDelegate 
	connectionIdentifier:(NSString *)theIdentifier URL:(NSURL *)theURL
	deliveryOptions:(MGTwitterEngineDeliveryOptions)theDeliveryOptions
{
	if ((self = [super init]) != nil)
	{
		json = [theJSON retain];
		identifier = [theIdentifier retain];
		URL = [theURL retain];
		deliveryOptions = theDeliveryOptions;
		delegate = theDelegate;
		
		if (deliveryOptions & MGTwitterEngineDeliveryAllResultsOption)
		{
			parsedObjects = [[NSMutableArray alloc] initWithCapacity:0];
		}
		else
		{
			parsedObjects = nil; // rely on nil target to discard addObject
		}
		
		if ([json length] <= 5)
		{
			// NOTE: this is a hack for API methods that return short JSON responses that can't be parsed by YAJL. These include:
			//   friendships/exists: returns "true" or "false"
			//   help/test: returns "ok"
			// An empty response of "[]" is a special case.
			NSString *result = [[[NSString alloc] initWithBytes:[json bytes] length:[json length] encoding:NSUTF8StringEncoding] autorelease];
			if (! [result isEqualToString:@"[]"])
			{
				NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];

				if ([result isEqualToString:@"\"ok\""])
				{
					[dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"ok"];
				}
				else
				{
					[dictionary setObject:[NSNumber numberWithBool:[result isEqualToString:@"true"]] forKey:@"friends"];
				}
			
				[self _parsedObject:dictionary];

				[parsedObjects addObject:dictionary];
			}
		}
		else
		{
            self.stack = [NSMutableArray array];
            
			// setup the yajl parser
			yajl_parser_config cfg = {
				0, // allowComments: if nonzero, javascript style comments will be allowed in the input (both /* */ and //)
				0  // checkUTF8: if nonzero, invalid UTF8 strings will cause a parse error
			};
			_handle = yajl_alloc(&callbacks, &cfg, NULL, self);
			if (! _handle)
			{
				return nil;
			}
			
			yajl_status status = yajl_parse(_handle, [json bytes], (unsigned int) [json length]);
			if (status != yajl_status_insufficient_data && status != yajl_status_ok)
			{
				unsigned char *errorMessage = yajl_get_error(_handle, 0, [json bytes], (unsigned int) [json length]);
				MGTWITTER_LOG_PARSING(@"MGTwitterYAJLParser: error = %s", errorMessage);
				[self _parsingErrorOccurred:[NSError errorWithDomain:@"YAJL" code:status userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:(char *)errorMessage] forKey:@"errorMessage"]]];
				yajl_free_error(_handle, errorMessage);
			}

			// free the yajl parser
			yajl_free(_handle);
		}
		
		// notify the delegate that parsing completed
		[self _parsingDidEnd];
	}
	
	return self;
}


- (void)dealloc
{
    self.stack = nil;
    self.currentDictionary = nil;
    self.currentArray = nil;

	[parsedObjects release];
	[json release];
	[identifier release];
	[URL release];
	
	delegate = nil;
	[super dealloc];
}

- (void)parse
{
	// empty implementation -- override in subclasses
}

#pragma mark - Stack

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
        MGTWITTER_LOG_PARSING(@"popped %@", [popped class]);
        if ([popped isKindOfClass:[NSMutableArray class]])
        {
            MGTWITTER_LOG_PARSING(@"popped array with key %@", self.currentKey);
            self.currentArray = popped;
        }
        else
        {
            MGTWITTER_LOG_PARSING(@"popped dictionary with key %@", self.currentKey);
            self.currentDictionary = popped;
        }
    }
}

#pragma mark - Parser Support

- (void)addValue:(id)value
{
    
    if (self.currentArray)
    {
        MGTWITTER_LOG_PARSING(@"added item: %@ (%@) to array", value, [value class]);
        [self.currentArray addObject:value];
    }
    else if (self.currentDictionary)
    {
        if (self.currentKey == nil)
        {
            MGTWITTER_LOG_PARSING(@"added item: %@ (%@) with nil key", value, [value class]);
        }

        else if (value == nil)
        {
            MGTWITTER_LOG_PARSING(@"added nil item with key %@", self.currentKey);
        }
        
        MGTWITTER_LOG_PARSING(@"added item: %@ (%@) to dictionary as key %@", value, [value class], self.currentKey);
        [self.currentDictionary setObject:value forKey:self.currentKey];
    }
	else
    {
        MGTWITTER_LOG_PARSING(@"root item: %@ (%@)", value, [value class]);
        [self _parsedObject:value];			
        [parsedObjects addObject:value];
    }
    self.currentKey = nil;
}

- (void)startDictionary
{
	MGTWITTER_LOG_PARSING(@"dictionary start");
	
	NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
         
    [self pushStack];
    self.currentDictionary = newDictionary;
    self.currentArray = nil;    
}

- (void)endDictionary
{
	MGTWITTER_LOG_PARSING(@"dictionary end %@", self.currentDictionary);
    NSMutableDictionary* dictionary = self.currentDictionary;
    [self popStack];
    [self addValue:dictionary];
}

- (void)startArray
{
	MGTWITTER_LOG_PARSING(@"array start");
	
	NSMutableArray* newArray = [NSMutableArray array];
    [self pushStack];
    self.currentDictionary = nil;
    self.currentArray = newArray;
	
}

- (void)endArray
{
	MGTWITTER_LOG_PARSING(@"array end %@", self.currentArray);
    NSMutableArray* array = self.currentArray;
    [self popStack];
    [self addValue:array];
}

#pragma mark Delegate callbacks

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((delegate != nil) && [delegate respondsToSelector:selector]);
}

- (void)_parsingDidEnd
{
    // Forward appropriate message to _delegate
    if ([self _isValidDelegateForSelector:@selector(genericResultsReceived:forRequest:)] && [parsedObjects count] > 0)
        [delegate genericResultsReceived:parsedObjects forRequest:identifier];
}

- (void)_parsingErrorOccurred:(NSError *)parseError
{
    if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[delegate requestFailed:identifier withError:parseError];
}

- (void)_parsedObject:(NSDictionary *)dictionary
{
	if (deliveryOptions & MGTwitterEngineDeliveryIndividualResultsOption)
        if ([self _isValidDelegateForSelector:@selector(receivedObject:forRequest:)])
            [delegate receivedObject:dictionary forRequest:identifier];
}

@end
