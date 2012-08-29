// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@class ECTwitterImage;
@class ECTwitterTweet;
@class ECTwitterUser;
@class ECTwitterEngine;
@class ECTwitterID;

/// Cache of Twitter related entities.
///
/// This is a high level abstraction for Twitter, which deals in entities such as
/// "user", "tweet", and so on.
///
/// The cache is attached to an <ECTwitterEngine> object, and uses it internally
/// to perform twitter operations as required.
///
/// Users of the cache should be able to simply request model objects from it,
/// and manipulate them using their properties and methods. The cache handles
/// any underlying calls to Twitter to fetch or change data.

@interface ECTwitterCache : NSObject 

/// --------------------------------------------------------------------------
/// @name Properties
/// --------------------------------------------------------------------------

/// The engine that this cache will use.

@property (strong, nonatomic) ECTwitterEngine* engine;

/// Default user to use to authenticate calls that require authentication.
/// Most calls have at least one user associated with them. If that user
/// doesn't have authentication information associated with it, then this
/// user's info will be used instead.
@property (strong, nonatomic) ECTwitterUser* defaultAuthenticatedUser;


/// --------------------------------------------------------------------------
/// @name Initialising new ECTwitterEngine objects
/// --------------------------------------------------------------------------

/// Initialise a new cache.
///
/// @param engine The engine that this cache will use to fetch data.

- (id)initWithEngine:(ECTwitterEngine*)engine;


/// --------------------------------------------------------------------------
/// @name Refreshing Object Data
/// --------------------------------------------------------------------------

/// Given a dictionary of user information, update a user object in the cache
/// creating it first if we didn't already have it.
/// @param info Dictionary containing a description of the user.
/// @return The associated user object.

- (ECTwitterUser*)addOrRefreshUserWithInfo:(NSDictionary*)info;

/// Given a dictionary of tweet information, update a tweet object in the cache,
/// creating it first if we didn't already have it.
/// @param info Dictionary containing a description of the tweet.
/// @return The associated tweet object.

- (ECTwitterTweet*)addOrRefreshTweetWithInfo:(NSDictionary*)info;


/// --------------------------------------------------------------------------
/// @name Obtaining Cached Objects
/// --------------------------------------------------------------------------

/// Return the tweet with a given id.
/// If the tweet didn't exist in the cache, one will be created, so that
/// this routine always returns a valid object. However, newly created
/// objects will start off with no information filled in. Generally, the
/// cache will then fetch the object information in the background,
/// posting a <ECTwitterTweetUpdated> notification when the information
/// has been filled in.
///
/// @param tweetID The ID of the tweet to return.
/// @return A tweet object.

- (ECTwitterTweet*)tweetWithID:(ECTwitterID*)tweetID;


/// Return the user with a given id.
/// If the user didn't exist in the cache, one will be created, so that
/// this routine always returns a valid object. However, newly created
/// objects will start off with no information filled in. Generally, the
/// cache will then fetch the object information in the background,
/// posting a <ECTwitterUserUpdated> notification when the information
/// has been filled in.
///
/// @param userID The ID of the user to return.
/// @return A user object.

- (ECTwitterUser*)userWithID:(ECTwitterID*)userID;

/// Like <userWithID:>, but with an extra parameter will allows you to suppress fetching of new data.
/// @param userID The ID of the user to return.
/// @param requestIfMissing If YES, missing objects will be requested from Twitter. If NO, an empty object will simply be requrned.
/// @return A user object.

- (ECTwitterUser*)userWithID:(ECTwitterID*)userID requestIfMissing:(BOOL)requestIfMissing;


/// Return the user with a given name, or nil if we don't have a user with that name cached.
/// If we can't find the user, we schedule a lookup for it, and return nil. In this situation,
/// clients can listen for <ECTwitterUserUpdated> notifications and check to see if it's the
/// user they're looking for.
/// We can't just return a blank ECTwitterUser object here because every object needs to
/// at least have the ID filled in, and we don't know what it is yet.
///
/// @param name The twitter name of the user we're looking for.
/// @return The twitter user, or nil if we couldn't find it.

- (ECTwitterUser*)userWithName:(NSString*)name;


/// Ensure that the name for the given user is cached, so that it
/// can be looked up by name as well as id.
/// @note This is for internal use, and shouldn't need to be called by client code.
///
/// @param user The user who's name we want to cache.

- (void)cacheUserName:(ECTwitterUser*)user;


/// Return an image for the object with a given ID.
/// The image may be fetched on demand, or cached locally.
///
/// @param imageID The ID of the object associated with the image.
/// @param url The URL of the image.
/// @return The image.

- (ECTwitterImage*)imageWithID:(ECTwitterID*)imageID URL:(NSURL*)url;


/// Return the tweet with a given ID, if it's in the cache. Otherwise returns nil.
/// @param tweetID The ID of the tweet we're looking for.
/// @return The tweet object, or nil if we don't have that tweet cached.

- (ECTwitterTweet*)existingTweetWithID:(ECTwitterID*)tweetID;


/// Return the user with a given ID, if it's in the cache. Otherwise returns nil.
/// @param userID The ID of the user we're looking for.
/// @return The user object, or nil if we don't have that user cached.

- (ECTwitterUser*)existingUserWithID:(ECTwitterID*)userID;

/// Return all the users that we know about.
/// @return An array of all cached users.

- (NSArray*)allUsers;

/// --------------------------------------------------------------------------
/// @name Adding To The Cache
/// --------------------------------------------------------------------------


/// Add a tweet object to the cache.
/// The tweet will replace any previous object with the same ID.
/// @param tweet The tweet to add.
/// @param tweetID The ID of the new tweet.

- (void)addTweet:(ECTwitterTweet*)tweet withID:(ECTwitterID*)tweetID;


/// Add a user object to the cache.
/// The user will replace any previous object with the same ID.
/// @param user The user to add.
/// @param userID The ID of the new user.

- (void)addUser:(ECTwitterUser*)user withID:(ECTwitterID*)userID;



/// --------------------------------------------------------------------------
/// @name Authentication
/// --------------------------------------------------------------------------

/// Return an authenticated user with a given screen name.
/// If we've already authenticated the user, it will be returned.
/// If not, nil is returned. In that case, the client should call <authenticatedUserWithName:password:> to perform the authentication.
///
/// @param name The screen name of the twitter user.
/// @return The twitter user, or nil if no authenticated user with that name is cached.

- (ECTwitterUser*)authenticatedUserWithName:(NSString*)name;


/// Request authentication from Twitter for a given user.
/// If the authentication succeeds, a <ECTwitterUserAuthenticated> notification will be posted, using the name object passed in as a key.
/// Calling <authenticatedUserWithName:> will then return the cached user object.
/// If the authentication fails, a <ECTwitterUserAuthenticationFailed> notification will be posted, using the name object passed in as a key.
///
/// @param name The twitter screen name of the user.
/// @param password The password for the user.

- (void)authenticateUserWithName:(NSString*)name password:(NSString*)password;


/// Return all authenticated users.
/// @return An array containing all the users that we have authentication info for.
- (NSArray*)authenticatedUsers;

/// --------------------------------------------------------------------------
/// @name Saving and Loading
/// --------------------------------------------------------------------------

/// Save all cached objects to disc.
/// Should be called when the application is going away (or at any other appropriate time).

- (void)save;

/// Load all cached objects from disc. Should be called once at startup.

- (void)load;

+ (ECTwitterCache*)decodingCache;

/// --------------------------------------------------------------------------
/// @name Notifications
/// --------------------------------------------------------------------------

/// An <ECTwitterUser> object has been refreshed.
/// The object associated with the <NSNotification> is the <ECTwitterUser> object that has been updated.

extern NSString *const ECTwitterUserUpdated;

/// A user with a given screen name has been authenticated.
/// The object associated with the <NSNotification> is the screen name passed in to the original authentication call.

extern NSString *const ECTwitterUserAuthenticated;

/// A user with a given screen name has failed to authenticate.
/// The object associated with the <NSNotification> is the screen name passed in to the original authentication call.

extern NSString *const ECTwitterUserAuthenticationFailed;

/// An <ECTwitterTweet> object has been refreshed.
/// The object associated with the <NSNotification> is the <ECTwitterTweet> object that has been updated.

extern NSString *const ECTwitterTweetUpdated;


/// A timeline (list of Tweets) has been refreshed.
/// The object associated with the <NSNotification> is the <ECTwitterTimeline> object that has been updated.

extern NSString *const ECTwitterTimelineUpdated;

@end
