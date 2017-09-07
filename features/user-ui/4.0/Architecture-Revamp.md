User Console 4.0 Architecture Revamp


Kamal Gill

 _September, 2013_ 






## Background and Motivation
The User Console architecture as of the 3.4 release is built on a smart client/dumb proxy architecture, with Tornado (Python) as the proxy and jQuery, Backbone.js, and Rivets comprising the client-side, single-page app (SPA) framework.


![](images/architecture/worddav68113d7a58dfa174a019cc68fa03824c.png)








## Drawbacks of Existing Application
The existing application architecture has numerous drawbacks.  A few are listed here, in no particular order.


 **Limitations of Browser-based Routing** : The 3.4 console is a single-page application, with all routing handled client-side via hashtags (e.g. [{+}](http://localhost:8888/#dashboard)[http://localhost:8888/#dashboard+](http://localhost:8888/#dashboard+)).  This has presented problems with allowing a browser to remember a user's login credentials, since the browser's save password prompt expects a true page redirect to offer the prompt (see EUCA-7534 [https://eucalyptus.atlassian.net/browse/EUCA-7534](https://eucalyptus.atlassian.net/browse/EUCA-7534)).  Also, the hashtag URL scheme isn't flexible enough for our purposes.  For example, there isn't clean support for arbitrarily-nested hierarchies, a required feature as we look to support a Walrus/S3 front-end [{+}](https://eucalyptus.atlassian.net/browse/EUCA-4314)[https://eucalyptus.atlassian.net/browse/EUCA-4314+](https://eucalyptus.atlassian.net/browse/EUCA-4314+) in our User Console.


 **Lack of modules, packages, and namespaces** :  JavaScript has eschewed packages and namespaces "Packages, namespaces, and early binding from ECMAScript 4 are no longer included for planned releases" – [{+}](http://en.wikipedia.org/wiki/ECMAScript)[http://en.wikipedia.org/wiki/ECMAScript+](http://en.wikipedia.org/wiki/ECMAScript+), making it a challenge to structure non-trivial applications.  Our use of RequireJS has alleviated the lack of modules to some extent, but the single-page app approach doesn't gracefully handle sloppy code errors.  For example, omitting the 'var' prefix hoists a variable into the global scope, causing unintended side effects that are difficult to debug.


 **Lack of unit tests** :  This is not a framework/architecture limitation per se, but it has traditionally been a challenge to write unit tests and test code coverage in JavaScript.  Our lack of unit test coverage in the existing app is a testament to this challenge.


 **Lack of fine-grained access control** :  The app currently assumes only two roles (authenticated or not), and view-level or object-level access control is non-existent.  Our current architecture isn't suited to support role-based and policy-based access control (a.la. IAM), a requirement for the 4.0 release [{+}](https://eucalyptus.atlassian.net/browse/PRD-54)[https://eucalyptus.atlassian.net/browse/PRD-54+](https://eucalyptus.atlassian.net/browse/PRD-54+).


 **Lack of component architecture** :  Due to the existing single-page app approach, a careless JavaScript error can bring down the entire app.  Some progress has been made in introducing a separation of concerns (e.g. Backbone models, collections, and views with Rivets templates), but the pieces are not cleanly isolated into decoupled building blocks.


 **Lack of extensibility** :  It is difficult, if not impossible, for a customer to customize a component of the application and have those customizations persist during an upgrade.  This applies not only to functional components, but also the theme-ability of the app.


 **Lack of static asset management** :  The 3.4 console delivers static CSS and JavaScript resources unminified and uncompressed.  Introducing a smarter asset delivery pipeline would significantly improve the performance of the application.


 **Non-standard i18n implementation** :  The current console (as of 3.4) has taken a "roll your own" approach with i18n, handling translation strings in JavaScript rather than adopting standard gettext [{+}](http://en.wikipedia.org/wiki/Gettext)[http://en.wikipedia.org/wiki/Gettext+](http://en.wikipedia.org/wiki/Gettext+) infrastructure to deliver locale-based translations.


 **Lack of HttpOnly cookie support** : According to OWASP, the majority of cross-site scripting (XSS) attacks target theft of session cookies [{+}](https://www.owasp.org/index.php/HttpOnly)[https://www.owasp.org/index.php/HttpOnly+](https://www.owasp.org/index.php/HttpOnly+).  A server could help mitigate this issue by setting the HTTPOnly flag on a cookie it creates, indicating the cookie should not be accessible on the client.  However, since form submissions are handled purely in JavaScript in the 3.4 console, enabling the HttpOnly flag would break form handling and render the app inoperable.


 **Non-standard template system** :  Our current approach for HTML templates involves the use of pieces of HTML shoved inside <script> tags.  While this approach is substantially better than generating HTML via JavaScript DOM operations, it offers little to no support for tag validation and isn't secure by default (i.e. XSS prevention via whitelisting of tags isn't automatic).


 **Lack of server-side form validation** :  Due to our dumb proxy approach, form validation is done entirely client-side, with no fallback to the server-side.  This has security implications that are beyond the scope of this document.


 **Limitations of client-side, multi-faceted search** :  Searching AWS public images on the client currently requires fetching a large dataset (dozens of MB), converting it to JSON, and iterating over the properties of the JSON objects in the collection [{+}](https://eucalyptus.atlassian.net/browse/EUCA-7422)[https://eucalyptus.atlassian.net/browse/EUCA-7422+](https://eucalyptus.atlassian.net/browse/EUCA-7422+), a terribly inefficient process that usually results in a "Do you want to stop this unresponsive script" (or similar) warning in the browser.






# Proposed Changes for 4.0 Console
The 3.4 Console is on the right track by adopting a Python-based Web framework.  4.0 can take us much further by moving more of the application concerns server-side.  Our current Python Web framework, Tornado, doesn't offer a rich enough feature set to address many of the drawbacks detailed above.  



KAMAL: I'd like to see some more information in here about addressing the UX concerns with the current arch we discussed in the SB summit, please. Can you go through this list at [{+}](https://docs.google.com/a/eucalyptus.com/document/d/1CzwiKzNzp0OgzNx67gD2Itgj-wJGOkBKvzOC7SanLdI/edit?usp=sharing)[https://docs.google.com/a/eucalyptus.com/document/d/1CzwiKzNzp0OgzNx67gD2Itgj-wJGOkBKvzOC7SanLdI/edit?usp=sharing+](https://docs.google.com/a/eucalyptus.com/document/d/1CzwiKzNzp0OgzNx67gD2Itgj-wJGOkBKvzOC7SanLdI/edit?usp=sharing+) and be sure all the concerns are accounted for in the arch redo so we can scope and plan for them?





## Python Web Framework
Although there are many Python-based Web frameworks to choose from, three have emerged as the leading options based on their vibrant communities.  Django [{+}](https://www.djangoproject.com/)[https://www.djangoproject.com/+](https://www.djangoproject.com/+) is arguably the leading framework based on community size, with Pyramid [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/)[http://docs.pylonsproject.org/projects/pyramid/en/latest/+](http://docs.pylonsproject.org/projects/pyramid/en/latest/+) and Flask [{+}](http://flask.pocoo.org/)[http://flask.pocoo.org/+](http://flask.pocoo.org/+) rounding out the other two top spots.  


 **Django** 


The OpenStack project has adopted Django as their framework of choice for their UI Dashboard (Horizon) [{+}](https://github.com/openstack/horizon)[https://github.com/openstack/horizon+](https://github.com/openstack/horizon+), begging the question whether it should be our selected framework as well.  Although Django has some clear advantages, it does have a few significant drawbacks.  


* Django heavily assumes a Web application is backed by a relational database [{+}](https://docs.djangoproject.com/en/dev/topics/db/queries/)[https://docs.djangoproject.com/en/dev/topics/db/queries/+](https://docs.djangoproject.com/en/dev/topics/db/queries/+), which introduces significant amount of clutter when an applications doesn't require a relational database.
* Django's regex-based URL routing scheme is cumbersome to work with and doesn't support arbitrarily-nested hierarchies.
* Django's template system isn't based on a W3C standard, and doesn't easily support multiple templating frameworks [{+}](https://docs.djangoproject.com/en/dev/ref/templates/)[https://docs.djangoproject.com/en/dev/ref/templates/+](https://docs.djangoproject.com/en/dev/ref/templates/+).
* Django's configuration infrastructure is spartan, making it difficult to swap out settings based on deployment targets (e.g. development vs. QA vs. prod)
* Django doesn't offer a clean infrastructure for pluggability and extension points.





 **Flask** 


Flask [{+}](http://flask.pocoo.org/)[http://flask.pocoo.org/+](http://flask.pocoo.org/+) is a lightweight framework that works great with non-SQL backends, offering a clean starting point for small to midsize apps, light enough to be a good fit for building Google App Engine apps [{+}](https://github.com/kamalgill/flask-appengine-template)[https://github.com/kamalgill/flask-appengine-template+](https://github.com/kamalgill/flask-appengine-template+). However Flask also has a few drawbacks:


* Flask's template system [{+}](http://jinja.pocoo.org/docs/)[http://jinja.pocoo.org/docs/+](http://jinja.pocoo.org/docs/+) is very similar to Django's template system and isn't based on a W3C standard.
* Although Flask offers extensibility via Blueprints [{+}](http://flask.pocoo.org/docs/blueprints/)[http://flask.pocoo.org/docs/blueprints/+](http://flask.pocoo.org/docs/blueprints/+), it isn't well-suited for medium to large applications yet.
* Flask is relatively young and, although there are many extensions [{+}](http://flask.pocoo.org/extensions/)[http://flask.pocoo.org/extensions/+](http://flask.pocoo.org/extensions/+), it doesn't offer a rich library of third-party packages.



 **Pyramid** 


Although Pyramid officially launched late 2010 [{+}](http://en.wikipedia.org/wiki/Pylons_project)[http://en.wikipedia.org/wiki/Pylons_project+](http://en.wikipedia.org/wiki/Pylons_project+), it's precursor (repoze.bfg) was in active development for many years prior, and the project was renamed Pyramid in December 2010.  Pyramid has emerged as the Python Web framework of choice for those looking to build scalable Web apps that are not necessarily backed by a relational database [{+}](http://www.sixfeetup.com/blog/pyramid-for-rapid-development-projects)[http://www.sixfeetup.com/blog/pyramid-for-rapid-development-projects+](http://www.sixfeetup.com/blog/pyramid-for-rapid-development-projects+).





## Why Pyramid for the User Console?
Instead of providing a dump of Pyramid's features here, let's discuss how the framework will address the drawbacks listed earlier in this document.




 **Routing** 


Moving routing to the server will allow a clean and flexible URL scheme to be used.  Pyramid's routing framework allows clean URLs that can be arbitrarily nested and map easily to manually-configured hierarchies via URL Dispatch [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/urldispatch.html)[http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/urldispatch.html+](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/urldispatch.html+), and it even supports arbitrarily-nested hierarchies via a mechanism known as Traversal [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/traversal.html)[http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/traversal.html+](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/traversal.html+), first pioneered by the Zope [{+}](http://en.wikipedia.org/wiki/Zope)[http://en.wikipedia.org/wiki/Zope+](http://en.wikipedia.org/wiki/Zope+) application server in 1995.  Pyramid also offers predicate-based view configuration [{+}](http://docs.pylonsproject.org/projects/pyramid/en/1.0-branch/narr/viewconfig.html)[http://docs.pylonsproject.org/projects/pyramid/en/1.0-branch/narr/viewconfig.html+](http://docs.pylonsproject.org/projects/pyramid/en/1.0-branch/narr/viewconfig.html+), a powerful way to map requests to handlers (views) based on conditions such as the request method, headers, clicked form buttons, XHR transports, etc.


 **Unit Testing** 


The developers of Pyramid are proud of the fact that the framework offers 100% test coverage.  Pyramid's authors firmly adhere to a test-driven development approach, and the framework works nicely with a wide variety of unit testing, functional testing, and integration testing tools [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/testing.html)[http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/testing.html+](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/testing.html+).


 **Access Control** 


Pyramid offers extensive support for fine-grained, role-based access control that goes well beyond other frameworks.  Pyramid's authorization scheme can (optionally) attach an access control policy to a context, allowing access control based not only on roles, but also on the viewed context [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/api/authorization.html)[http://docs.pylonsproject.org/projects/pyramid/en/latest/api/authorization.html+](http://docs.pylonsproject.org/projects/pyramid/en/latest/api/authorization.html+).  For example, while other frameworks may offer an "a user may view a blog post" rule, Pyramid supports an "a user may view  **this**  blog post" access control policy relatively easily.


 **Component Architecture and Extensibility** 


Pyramid has been designed with extensibility in mind, offering hooks to override configuration, views, routes (URLs), static assets and other layers [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/extending.html)[http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/extending.html+](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/extending.html+) of the architecture.  It is relatively simple and is the encouraged approach to build a Pyramid application from multiple python packages as building blocks that are easily snapped together like Lego bricks.


 **Internationalization** 


Pyramid fully supports i18n (internationalization) and l10n (localization) [{+}](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/i18n.html#i18n-chapter)[http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/i18n.html#i18n-chapter+](http://docs.pylonsproject.org/projects/pyramid/en/latest/narr/i18n.html#i18n-chapter+), leveraging the standard gettext approach for translation strings.


 **Standard Template System that is Secure by Default** 


Pyramid includes support for the Chameleon [{+}](http://chameleon.readthedocs.org/en/latest/)[http://chameleon.readthedocs.org/en/latest/+](http://chameleon.readthedocs.org/en/latest/+), an XHTML-based template system that sanitizes user-based input by default, mitigating XSS attack vectors.


 **Form Validation** 


Pyramid encourages the use of Deform [{+}](http://docs.pylonsproject.org/projects/deform/en/latest/index.html)[http://docs.pylonsproject.org/projects/deform/en/latest/index.html+](http://docs.pylonsproject.org/projects/deform/en/latest/index.html+) as the Python-based form library of choice, with Colander [{+}](http://docs.pylonsproject.org/projects/colander/en/latest/)[http://docs.pylonsproject.org/projects/colander/en/latest/+](http://docs.pylonsproject.org/projects/colander/en/latest/+) providing helper methods that work well when validating non-relational data sources such as JSON.







## Other Back-end Concerns


 **Search-oriented Enhancements** 


Searching the AWS list of public images is a terribly inefficient operation, requiring a download of the entire image set and filtering that collection locally.  As of the 3.4 console, we load that entire image and search that collection client-side, which risks locking up the browser with a "Are you sure you want to continue running scripts on this page?" warning.



One proposed solution would be to download the public image set (as a periodic task, perhaps updated no more than once an hour) and index that image set in a faceted search engine (e.g. ElasticSearch).  Pyramid would query ElasticSearch via pyelasticsearch [{+}](https://github.com/rhec/pyelasticsearch)[https://github.com/rhec/pyelasticsearch+](https://github.com/rhec/pyelasticsearch+), only returning the results relevant to the selected facets, thus delivering a much smaller payload to the browser.


 **Periodic Tasks and Worker Queues** 


The author advocates using Celery [{+}](http://celeryproject.org/)[http://celeryproject.org/+](http://celeryproject.org/+) with RabbitMQ to handle long-running (i.e. > 10 second) and periodic (cron-like) tasks.  Many of the console operations that involve state changes in the Eucalyptus cloud (e.g. creating a large instance) aren't immediate enough for the User Console UI to wait for the process to be complete before alerting the user of the successful operation (or failure).  Celery will be leveraged to manage the worker queues and the periodic tasks (e.g. downloading public image set lists from AWS).









## Front-End Concerns


 **Responsive Web Layout** 


We would like to support responsive Web design in the 4.0 release of the User Console.  Two front-end layout frameworks have emerged in recent years as the front-runners in the responsive web design community, Twitter Bootstrap [{+}](http://getbootstrap.com/)[http://getbootstrap.com/+](http://getbootstrap.com/+) and Zurb Foundation [{+}](http://foundation.zurb.com/)[http://foundation.zurb.com/+](http://foundation.zurb.com/+).  While Bootstrap has the lion's share of developer attention as the most-watched project on GitHub with over 58k followers, Zurb Foundation is in the author's experience the preferred choice for our project due to a few reasons.





* Bootstrap assumes a "greenfield" (i.e. starting from scratch) environment and doesn't always play well with third-party libraries and frameworks.
* Bootstrap offers far more styles out of the box, with rounded corners to boot.  However this requires far more customization if the visual style is modified to look, for lack of a better term, "non-bootstrappy".
* Foundation's CSS is better namespaced to avoid collisions.
* Foundation's grid system is known to be more flexible and sophisticated.
* Foundation has supported responsive and mobile-first design approaches throughout it's history, while Bootstrap wasn't responsive until release 2 (as an add-on), and the responsive features weren't part of the core until release 3 (only recently released).



 **Preferred JavaScript MVC Framework** 


Backbone is a lightweight framework that stays out of your way by offering no opinions on many user interface concerns.  However, it is missing some key features such as templating, and UI components, and it's use of heavyweight objects with getters and setters rather than plain old JavaScript objects makes it more difficult to understand, debug, and unit test.



AngularJS [{+}](http://angularjs.org/)[http://angularjs.org/+](http://angularjs.org/+) has emerged as solid alternative for applications looking to support a richer feature set than what Backbone offers.  Angular adheres to an "HTML should look like HTML and JavaScript should look like JavaScript" philosophy, since templates in Angular are plain old HTML (rather than snippets embedded in <script> tags) and JavaScript "models" and "collections" are plain old JavaScript objects, keeping code far more simple and more easily tested.  Angular is also future-proof, with its killer Directive [{+}](http://docs.angularjs.org/guide/directive)[http://docs.angularjs.org/guide/directive+](http://docs.angularjs.org/guide/directive+) feature modeled on the upcoming W3C Web Components [{+}](http://www.w3.org/TR/2013/WD-components-intro-20130606/)[http://www.w3.org/TR/2013/WD-components-intro-20130606/+](http://www.w3.org/TR/2013/WD-components-intro-20130606/+) spec.


 **Static Asset Management** 


Introducing a smarter Web framework would allow more intelligent handling of static CSS and JS assets, allowing the production version of the console to easily bundle combined and minified styles and scripts.  The current app's static resource handling doesn't distinguish between development and production environments.  Pyramid integrates nicely with leading Python-based asset management libraries such as webassets [{+}](https://github.com/sontek/pyramid_webassets)[https://github.com/sontek/pyramid_webassets+](https://github.com/sontek/pyramid_webassets+) to avoid overloading the browser with HTTP requests [{+}](http://developer.yahoo.com/blogs/ydn/high-performance-sites-rule-1-fewer-http-requests-7163.html)[http://developer.yahoo.com/blogs/ydn/high-performance-sites-rule-1-fewer-http-requests-7163.html+](http://developer.yahoo.com/blogs/ydn/high-performance-sites-rule-1-fewer-http-requests-7163.html+).





## Proposed 4.0 User Console Architecture
To summarize, the 4.0 Console replaces the Tornado proxy with Pyramid as the Python Web framework.  Boto [{+}](https://github.com/boto/boto)[https://github.com/boto/boto+](https://github.com/boto/boto+) continues to be leveraged as the library of choice to interface with AWS and Eucalyptus.  ElasticSearch will act as an intermediary "cache" layer to offer optimized facet-based searching of AWS public image sets, and Celery/RabbitMQ will handle periodic tasks and worker queues.  On the front-end, Zurb Foundation will be the responsive layout/grid framework, and AngularJS will be the JavaScript MVC library (replacing Backbone/Rivets).  It is important to emphasize that version 4.0 will not be a single-page application due to the scalability and maintainability challenges implied in the SPA approach.


![](images/architecture/worddav356a206335a32cdb87d82e2a82547acb.png)








## Risks/Concerns
There are a few concerns with what appears to be a "rip and replace" approach for the 4.0 console.  Let's address these in a Q-and-A format.


 **Does the new architecture mean we're starting from scratch?** 


Not entirely.  We will not need to redesign the interfaces for the existing sections, but we may take advantage of the fresh approach and look to offer a cleaner user experience, especially as we transition to a mobile-first [{+}](http://www.abookapart.com/products/mobile-first)[http://www.abookapart.com/products/mobile-first+](http://www.abookapart.com/products/mobile-first+) design philosophy.  The new architecture will allow us to easily transition to a cleaner, less-cluttered interface as well as a simpler code base.


 **We are increasing our number of dependencies for the Console. Won't this make it more difficult to install or to set up as a development environment?** 


Packages will alleviate the production deployment install concerns, and we hope to offer scripts and use standard Python deployment strategies such as "pip install" to keep things simple.







## Unanswered Questions/Concerns


 **Storing State Server-side** 


PRD-36 [{+}](https://eucalyptus.atlassian.net/browse/PRD-36)[https://eucalyptus.atlassian.net/browse/PRD-36+](https://eucalyptus.atlassian.net/browse/PRD-36+) specifies capturing an audit trail of operations performed by users and account administrators in the admin console component of the 4.0 release, which likely requires a persistent data store (relational or non-relational) that the console will interface with.  As of the 3.4 User Console, we have not need to store state on the server for operations that are outside the scope of Euca or AWS API calls.  Many of the requirements in the admin console that fall in the reporting category (e.g. audit trail) will likely require a persistent store server-side, a topic that isn't addressed in this document (but probably should be).



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:user-ui]]
