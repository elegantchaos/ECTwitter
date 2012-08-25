ECTwitter is an open source Twitter library, written in Objective-C, for Mac and iOS projects.

The library is hosted on [github](http://github.com/elegantchaos/ECTwitter). 

You can clone it using the Git url <git://github.com/samdeane/ECTwitter.git>.

Full documentation is [available online](http://elegantchaos.github.com/ECTwitter/Documentation).

About The Library
--------------

This library is intended to provide two things:

- a high level model of the main twitter object types, with automatic caching and on-demand fetching of missing objects
- a low level interface which allows you to make generic twitter requests and run code when you receive responses

The high level model is intended to be the way you actually interact with ECTwitter. You can query it for typical objects (users, messages, timelines) and it deals transparently with the business of fetching the data. When new data arrives, you are informed using notifications.

The high level interface model uses the low level interface internally, and in general you shouldn't have to use it directly. It's there if you need it though - for example to access Twitter features that the high level model doesn't expose yet. 

The low level interface is designed to do all the housekeeping work of authenticating and submitting a request and parsing the results, but does the minimum of interpretation of the data it gets back.


Dependencies
----------------

The library has <Dependencies> on various other frameworks.

Because of this, there's also an [integration project](http://github.com/elegantchaos/ECTwitterIntegration) which contains an xcode workspace and all of the relevant frameworks as submodules. Using this repo is an easy way to ensure that you've got the right versions of everything you need (alternatively you can add the individual submodules to your project yourself).
