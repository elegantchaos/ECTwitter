ECTwitter is an open source Twitter library, written in Objective-C, for Mac and iOS projects.

The library is hosted on [github](http://github.com/samdeane/ECTwitter).

You can clone it using the Git url [git://github.com/samdeane/ECTwitter.git](git://github.com/samdeane/ECTwitter.git).

About The Library
--------------

This library is intended to provide two things:

- a simple interface which allows you to make generic twitter requests and run code when you receive responses
- a high level model of the main twitter object types, with automatic caching and on-demand fetching of missing objects 

Dependencies
----------------

The library is currently implemented on top of a fork of MGTwitterEngine, and therefore also depends on the libraries that MGTwitterEngine needs for OAuth and JSON support. However, the use of MGTwitterEngine is not exposed in the ECTwitter API, and to some extent it could be regarded as an implementation detail. I don't use a lot of the MGTwitterEngine functionality, so at some point I may just rip out the stuff that I do use and merge the code directly into ECTwitter.

ECTwitter also depends on [ECFoundation](/libraries/ecfoundation).

For More Information
--------------------

See [the ECTwitter home page](http://www.elegantchaos.com/libraries/ectwitter).
