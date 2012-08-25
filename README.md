ECTwitter is an open source Twitter library, written in Objective-C, for Mac and iOS projects.

The library is hosted on [github](http://github.com/samdeane/ECTwitter). You can clone it using the Git url git://github.com/samdeane/ECTwitter.git.

About The Library
--------------

This library is intended to provide two things:

- a simple interface which allows you to make generic twitter requests and run code when you receive responses
- a high level model of the main twitter object types, with automatic caching and on-demand fetching of missing objects

Dependencies
----------------

The library has <dependencies> on various other frameworks. Because of this, there's also an [integration git hub repo](git://github.com/samdeane/ECTwitterIntegration.git) which contains an xcode workspace and all of the relevant frameworks as submodules. Using this repo is an easy way to ensure that you've got the right versions of everything you need (alternatively you can add the individual submodules to your project yourself).

Most of these frameworks are also from Elegant Chaos, but two (ECOAuthConsumer and ECRegexpKitLite) are third party libraries that I've packaged up as proper frameworks. ECTwitter also depends on the YAJL framework, and contains some highly modified elements of MGTwitterEngine.

For More Information
--------------------

See [the ECTwitter documentation](http://elegantchaos.github.com/ECTwitter/Documentation).
