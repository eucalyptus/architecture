* [Description](#description)
* [Tracking](#tracking)
  * [Related Features](#related-features)
  * [Related Issues](#related-issues)
* [Analysis](#analysis)
  * [Threading / Asynchronicity](#threading-/-asynchronicity)
  * [Component Transaction Boundary](#component-transaction-boundary)
  * [Component Message Filtering](#component-message-filtering)
  * [Context Propagation](#context-propagation)
  * [Content Based Routing](#content-based-routing)
  * [Service Target Method Resolution](#service-target-method-resolution)
  * [Monitoring](#monitoring)
  * [Correlation Identifiers](#correlation-identifiers)
  * [Assumptions and Questions](#assumptions-and-questions)
* [Elements](#elements)
  * [Message Bus](#message-bus)
  * [Utilities / Threads](#utilities-/-threads)
  * [Bootstrap](#bootstrap)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
  * [Message](#message)
  * [Endpoint](#endpoint)
* [Milestones](#milestones)
  * [Sprint 1](#sprint-1)
* [Risks](#risks)
* [References](#references)



# Description
Replace Mule with Spring Integration.


# Tracking

* Status: Step #1, initial draft


## Related Features
Features in the 4.4/5.0 release that are relevant for this feature.


* [[5.0 SQS|5.0-SQS---Architectural-Analysis]] service configuration will need to use new approach, may have messaging requirements
* [[ELB using SWF|ELB-SWF-ARCHITECTURAL-ANALYSIS]] relies on threading changes for scalable long polling


## Related Issues

* [EUCA-12691 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-12691) configuration may use a different property or may be removed due to changes for this feature


# Analysis

## Threading / Asynchronicity
The threading model for spring integration is more flexible than mules. As part of the replacement we may want to use a design with fewer threads.

Currently we require blocked threads for local calls and remote calls are limited by a components thread pool size.


## Component Transaction Boundary
Calls between components must use distinct threads so that transactions are not shared across persistence contexts.


## Component Message Filtering
Mule configuration places "filters" by message type on the "pipes", we should evaluate if a similar approach is necessary for any replacement.


## Context Propagation
Request context is preserved for authorization use (i.e. with asynchronous calls where thread local context would be lost)


## Content Based Routing
Mule examines messages (types) to route to service implementations.


## Service Target Method Resolution
Resolving target messages to methods on service implementations is widely used mule behaviour that does not have an exact replacement in spring integration.


## Monitoring
The  _MuleSensor_  provides instrumentation for mule operations. We would need to implement a replacement for spring integration if we want to preserve this behaviour.


## Correlation Identifiers
We should ensure that messaging changes do not impact tracing functionality.


## Assumptions and Questions
Assumptions and open questions around requirements for the feature.

Assumptions:


* Minor limitations on service target method resolution are acceptable.

Open questions:


* Any impact on message tracing?
* Do we need to replace the  _MuleSensor_  functionality?
* Are any statistics gathered from mule particularly useful?


# Elements
![](images/architecture/mbus_elements.png)


## Message Bus
The "message bus" for services consists of the  _ServiceContext_  and  _ServiceContextManager_ . This component is responsible for the management of spring contexts and provides an API for synchronous and asynchronous message exchanges with service implementations.

 _ServiceContext_  configuration (cloud properties) should be updated and we should use a shared thread pool for all components by default.


## Utilities / Threads
Threads provides thread pools used by the messages bus.


## Bootstrap
Bootstrap manages the lifecycle of the message bus.


# Interactions

# Abstractions

## Message
A message is sent between components of the system. Messages are handled by service implementations.


## Endpoint
An endpoint represents a (component) destination for a Message. An endpoint may be equivalent to a service implementation, though some services have internal dispatch using distinct service implementations for a single component.


# Milestones

## Sprint 1

# Risks
Areas currently identified as risks:


* Threading with spring integration differs from mule


# References

* [Spring Integration Reference Manual (docs.spring.io)](http://docs.spring.io/spring-integration/docs/4.3.1.RELEASE/reference/htmlsingle/)
* [[Correlation ID in 4.2|Correlation-ID-in-4.2]]
* [[Architecture: Eucalyptus System Events|Architecture--Eucalyptus-System-Events]]
* [[Message bus design|Message-Bus-4.4]]





*****

[[tag:confluence]]
[[tag:rls-4.4]]
[[tag:wsstack]]
