* [Description](#description)
* [Model / Persistence](#model-/-persistence)
  * [Entities](#entities)
  * [Persistence Facades / DAOs](#persistence-facades-/-daos)
* [Service](#service)
  * [Implementation](#implementation)
  * [Messages and Bindings](#messages-and-bindings)
  * [Long Polling](#long-polling)
  * [Task Tokens](#task-tokens)
  * [Timeouts](#timeouts)
  * [Configuration](#configuration)
* [Client Framework](#client-framework)
  * [Client Configuration and Life Cycle](#client-configuration-and-life-cycle)
  * [Workflow Patterns](#workflow-patterns)



# Description
This document covers the implementation related to the [[SWF Architectural Analysis (ARCH-71, ARCH-82)|SWF-Architectural-Analysis-(ARCH-71,-ARCH-82)]]


# Model / Persistence
This section covers the entities and framework used for persistence for SWF elements.


## Entities
This diagram shows the SWF entities and their relationships:

![](images/architecture/4_1_swf_er.png)


## Persistence Facades / DAOs
For persistence of each entity there is an interface and associated implementation:

![](images/architecture/4_1_swf_persistence.png)

The persistence implementation is provided by a Persistence\* class which is annotated with  _@ComponentNamed_  so it can be discovered and injected where necessary (the _SimpleWorkflowService_  constructor for example).  _SwfPersistenceSupport_  has very limited functionality but specifies the super-types and exceptions for SWF specific  _AbstractPersistentSupport_  implementations.

The  _AbstractPersistentSupport_  class is not SWF specific, it provides a callback based API for entity persistence and is implemented using existing  _Entities_  and  _Transactions_  APIs.


# Service
This section covers functionality related to the user facing SWF service implementation.


## Implementation
The  _SimpleWorkflowService_  implements SWF actions. The class is annotated with  _@ComponentNamed_  so that dependencies can be injected for persistence and task token management.


## Messages and Bindings
Message classes are copied from the AWS SDK for Java. JSON message binding is performed via Jackson. Binding is performed by  _SimpleWorkflowBinding_  which implements  _ExceptionMarshallerHandler_  in order to respond with JSON format error messages.

For message binding the  _SwfJsonUtils_  utility class is used. Jackson is used for for JSON conversion and there is special handling for Dates to use the SWF required date format.


## Long Polling
Long polling is used to poll for decision and activity tasks. An internal stateful pollednotifications service is added to implement polling as this cannot easily be implemented directly in the stateless UFS SWF service.

![](images/architecture/4_1_swf_polled_notifications.png)

The  _NotifyClient_  is implemented using the usual  _AsyncRequests_  API. The  _PolledNotificationService_  tracks both pollers and pending notifications in memory so it can be responsive. There is also a mechanism for loading existing notifications via  _PolledNotificationChecker_  implementations. SWF provides  _PolledNotificationChecker_ s for both pending decision and activity tasks.

A limitation of the long polling implementation is that threads are currently blocked while waiting for notifications, this will impact system stability if there are too many clients performing long polling.


## Task Tokens
Decision and activity tasks are identified by tokens that are passed back into the service when the task handling is completed. The  _TaskTokenManager_  is used for token functionality:

![](images/architecture/4_1_swf_task_tokens.png)

 _TaskTokenManager_  handles encryption and decryption of task tokens.


## Timeouts
Timeouts for tasks, workflows, timers, and cleanup of deprecated resources are handled by the  _TimeoutManager_ .

Whenever a workflow execution or activity task is updated the timeout is calculated. The timeout manager periodically queries for expired timeouts and performs the necessary action(s).


## Configuration
Cloud properties for SWF are defined on the  _SimpleWorkflowProperties_  class.


# Client Framework

## Client Configuration and Life Cycle
 _WorkflowDiscovery_  and  _WorkflowRegistry_  classes detect any activity and workflow implementation classes annotated with  _@ComponentPart._ These detected classes are then used by the  _Config_ class, either directly or via the higher level _WorkflowClient_  API. The  _Config_  class also handles creating an AWS SDK for Java  _AmazonSimpleWorkflow_  that is integrated with our  _Topology_  and  _SecurityTokenManager_  functionality.

The  _WorkflowClient_  exposes start/stop life cycle methods that control the underlying Flow Framework workers.


## Workflow Patterns
Generic workflow patterns are implemented in  _WorkflowUtils_ . Support is currently limited to asynchronous polling.



*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:swf]]
