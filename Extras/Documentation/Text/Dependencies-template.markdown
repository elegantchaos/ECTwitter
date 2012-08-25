Dependencies
------------

ECTwitter depends on various other frameworks. 

Because of this, there's also an [integration project](http://github.com/elegantchaos/ECTwitterIntegration) which contains an xcode workspace and all of the relevant frameworks as submodules. Using this repo is an easy way to ensure that you've got the right versions of everything you need (alternatively you can add the individual submodules to your project yourself).

The project is intended to be dropped into an Xcode worksheet, along with all the other dependent frameworks.

On the mac everything is packaged as a proper framework. On iOS, we package things up as pseudo-frameworks. These behave like frameworks in most respects, but are actually static libraries linked at build time (as opposed to being dynamically linked at run time, as proper frameworks are).

EC Frameworks
-------------

The following frameworks are used:

- ECConfig
- ECLogging
- ECCore
- ECUnitTests (for unit testing only)

Third Party
-----------

ECTwitter also depends on:

- YAJL
- ECOAuthConsumer
- ECRegexpKitLite

(the latter two are versions of oauthconsumer and RegexpKitLite that I've bundled up to build as frameworks)

MGTwitterEngine
---------------

ECTwitter also contains some highly modified elements of MGTwitterEngine, by Matt Gemmell. Increasingly this code is being replaced, as ECTwitter is an attempt to replace MGTwitterEngine with something cleaner, but I'd very much like to acknowledge Matt's contribution, and the fact that some of my code is based on his, and some of the code in this engine was written by him.
