//
//  MGTwitterParserFactoryYAJLGeneric.h
//
//  Created by Sam Deane on 21/09/2010.
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//

#include <ECFoundation/ECLogging.h>

ECDeclareLogChannel(MGTwitterEngineChannel);
ECDeclareLogChannel(MGTwitterEngineParsingChannel);

#define MGTWITTER_LOG(...) ECDebug(MGTwitterEngineChannel, __VA_ARGS__)
#define MGTWITTER_LOG_PARSING(...) ECDebug(MGTwitterEngineParsingChannel, __VA_ARGS__)
