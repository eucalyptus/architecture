
# Overview
SWF was implemented and being used by CloudFormation, but it was not a supported service. The goal of this work is to harden SWF implementation so that 1) it can be a supported service in 4.3, and 2) additional services (ELB, imaging, etc) can depend on SWF.

Good intro to SWF, Flow framework, and glisten can be found here:[http://netflix.github.io/glisten/#/](http://netflix.github.io/glisten/#/)


# SWF

* Task coordination and state management
* Simple, low-level abstraction
* Decider and activities
* History and well-defined events
* SWF does the state machinery and you write your logic
* JSON request&response
* Flow Framework (Java/Ruby) for high level abstraction
* Glisten for even higher abstraction


# Current status
SWF design:[[Simple Workflow Service Design|swf-4.1-design]]


* Stateless service in UFS
* Special message binding for JSON request and response
* Relatively simpler service, querying&writing entities extensively
* Internal, extra service (PolledNotification) to implement long-polling
* TimeoutManager to periodically handle workflow/activity timeouts.
* TokenManager for encrypting&decrypting task tokens (to make it opaque?)
* Properties for various max-\* limits


# USAGE: CloudFormation

* Flow framework and glisten


# Issues

* Long-polling for tasks (TCP open for 60 sec)
* Scale issues (e.g.,[EUCA-11428 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-11428))
* Hibernate and relational DB as the limiting factor
* SWF as SPOF
* Troubleshooting, debugging when services depend on SWF
* Glisten
* No Python framework (only low-level plumbing via boto)





*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:swf]]
