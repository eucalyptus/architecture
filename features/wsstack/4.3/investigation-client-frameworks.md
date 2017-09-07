
## Overview
We can improve developer productivity by making it easier to correctly make calls between Eucalyptus services with support for error handling and retries.

We can improve system reliability by implementing established patterns for distributed systems failures such as circuit breaker and command patterns.


## Analysis

### Existing client frameworks
We generally use our internal framework for creating and sending messages between services. This framework "transparently" uses either a VM transport or HTTP transport with WS-Security depending on whether a message is local.

An older version of the AWS SDK for Java is used as a client for some services. This client uses an HTTP transport with AWS signature methods. This client is used where there are higher level libraries that require it (AWS Flow Framework) or where the REST API characteristics are desired (S3)


### Error propagation
Error propagation is currently complex as it depends on the client and transport in use. This increases the complexity of testing as the topology used impacts the behaviour.  _AsyncExceptions_ provides some support but it not integrated into the client.


### Endpoint selection
There will often be multiple endpoints available for a service (UFS), we should support a standard approach to endpoint selection based either on DNS information or directly on  _Topology_  information. Endpoint selection must support:


* Endpoint locality
* Failover


### Caller context
Internal messages include contextual information for impersonation, requested privileges and authorization contextual information (e.g. the source IP for the request)


### Message logging
It is possible to enable logging of messages and/or wire traces for clients but is not possible to do so selectively (e.g. for some services), simplifying logging of request/responses for clients would aid development and could also be useful for cloud operations.


### Retrying requests
Internal requests are not currently retried, requests made using the AWS client may be retried depending on the service and configuration. The appropriate strategies for retry/failover will vary and should be more easily configurable.


### Synchronous and asynchronous APIs
Both clients support synchronous and asynchronous service calls and both approaches are used.


### Client configuration
Clients (services?) will have different requirements for response timeouts, etc and we may want to make these separately configurable.


### Circuit breaker / command pattern
Use of circuit breaker and command patterns would help prevent cascading failures and allow for more graceful degradation of performance on partial cloud failures.

Circuit breakers should also be monitored (circuit open/closed) and may need to support manual reset in addition to automated recovery. The command is also a natural point for instrumentation on service performance.

Circuit breakers would be placed at a higher level than other concerns such as retry and failover so would likely be distinct from any specific client.


### External client for administrative APIs
We do not have an official (Java) client for Eucalyptus specific (administrative) APIs, though there is the unofficial YouAre SDK (extension of AWS SDK for Java)


### Higher level client
In addition to the lower level (service API based) clients we may want to have higher level clients for specific use cases (along the lines of the euca-resources-support module)


## Candidate solutions

### Service specific clients
Creating service specific sync and async clients would allow functionality to be added in a controlled way. We could introduce basic API support and add functionality as it is needed.


### Circuit breaker
This should be implemented in a way that allows usage of the circuit breaker other than web service clients. It would also make sense to support circuit breakers as an optional aspect of any client (for example by proxying a client interface)


## References

* [AWS Flow Framework (amazon.com)](https://aws.amazon.com/swf/details/flow/)
* [Netflix Hystrix (github.com)](https://github.com/Netflix/Hystrix)
* [YouAre SDK (github.com)](https://github.com/sjones4/you-are-sdk)



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:wsstack]]
