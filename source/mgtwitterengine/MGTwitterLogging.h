//
//  MGTwitterParserFactoryYAJLGeneric.h
//
//  Created by Sam Deane on 21/09/2010.
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//

// By default, logging will be enabled if DEBUG is set to 1, and disabled otherwise.
// You can provide your own definition of MGTWITTER_LOG to direct it elsewhere.

#ifndef MGTWITTER_LOG
#if DEBUG
#define MGTWITTER_LOG(...) NSLog(__VA_ARGS__)
#else
#define MGTWITTER_LOG(...)
#endif
#endif

// By default, logging of the parsers will be enabled if DEBUG_PARSING is set to 1, and disabled otherwise.
// You can provide your own definition of MGTWITTER_LOG_PARSING to direct it elsewhere.

#ifndef MGTWITTER_LOG_PARSING
#if DEBUG_PARSING
#define MGTWITTER_LOG_PARSING MGTWITTER_LOG
#else
#define MGTWITTER_LOG_PARSING(...)
#endif
#endif
