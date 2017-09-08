
## Overview
Quick changes that could improve development speed by reducing time spent debugging.


## Analysis

### Request/response logging
We should ensure it is simple to view request and response messages in some form for services. This should include both internal and external messages.


### Logging configuration changes
It should be easy to change logging configuration at runtime to ensure useful debugging output is available in the logs.


* setting the level for a logger
* log file threshold changes
* enabling exhaust / extreme logs


### Framework simplification
We should simplify the logging framework if possible to make changes easier. For example we could remove custom log levels if there is not a strong case for having them.


### Log file consolidation
We have many log files. We should ensure there is a well understood purpose for each log and remove any that are not necessary so there are fewer log files to check when looking for log output.

There could be a separate development logging configuration that ensured the available information was in a single location (on a host)


### Stack trace inclusion
A common code pattern is to drop exception information where there is an expected error. Often this will end up making information that is essential for debugging hard to find. We could have a separate option to included stack trace information or could include this information when debugging is enabled (though likely not appropriate for the DEBUG log level)

We sometimes drop include useful information in stack traces (e.g. chained SQL exceptions, see references)


### Simple workflow logs
As use of SWF expands it would be useful to have tools for displaying workflow events. This is less necessary for some services which can display a summary of events for users:


* Auto scaling activities
* CloudFormation stack events


### Service VM logs
Accessing logs from an instance managed by a service currently requires SSH access to the instance. For SSH access an administrator must have configured an SSH key prior to running the service instance. It is also hard to monitor service instances for logged errors as there is not currently any log aggregation.

The right solution for service VM logs is likely CloudWatch Logs.


## Candidate solutions

* Minor fixes for some of above identified issues
* Add tools for displaying workflow events
* Moving to a more recent logging framework such as Log4J 2 could reduce the work needed to address some issues


## References

* Proposed 4.1 feature : [[Monitoring Eucalyptus in 4.1 - Feature Requirements|monitoring-4.1-Monitoring-Feature-Requirements]]
* [[Correlation ID in 4.2|Correlation-ID-in-4.2]]
* [EUCA-6519 : Stacktraces should include root causes](https://eucalyptus.atlassian.net/browse/EUCA-6519)
* [CloudWatch Logs (docs.aws.amazon.com)](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatchLogs.html)
* [Log4J 2 (logging.apache.org)](http://logging.apache.org/log4j/2.x/)



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:wsstack]]
