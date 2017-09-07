* [Description](#description)
* [Tracking](#tracking)
* [Analysis](#analysis)
  * [Message Delivery](#message-delivery)
  * [Long Polling](#long-polling)
  * [Delay Queues / Message](#delay-queues-/-message)
  * [Visibility Timeout](#visibility-timeout)
  * [Dead Letter Queues](#dead-letter-queues)
  * [Shared Queues](#shared-queues)
    * [Simple API for Shared Queues](#simple-api-for-shared-queues)
    * [Advanced API for Shared Queues](#advanced-api-for-shared-queues)
  * [CloudWatch Metrics](#cloudwatch-metrics)
  * [Query API](#query-api)
  * [Interaction with other services](#interaction-with-other-services)
  * [JMS 1.1 Support](#jms-1.1-support)
  * [Amazon SQS Extended Client Library for Java](#amazon-sqs-extended-client-library-for-java)
  * [Requirements](#requirements)
    * [Minimum Viable Product](#minimum-viable-product)
    * [Additional Goals](#additional-goals)
* [Use Cases](#use-cases)
  * [Admin Use Cases](#admin-use-cases)
  * [User Use Cases](#user-use-cases)
* [Elements](#elements)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
* [Milestones](#milestones)
  * [Phase 1 (Tracer)](#phase-1-(tracer))
  * [Phase 2](#phase-2)
  * [Phase 3](#phase-3)
  * [Phase 4](#phase-4)
  * [Phase 5](#phase-5)
  * [Phase 6](#phase-6)
    * [Persistence Levels](#persistence-levels)
    * [Assumptions and Limitations](#assumptions-and-limitations)
* [References](#references)



# Description
Amazon Simple Queue Service (Amazon SQS) is a messaging queue service. It handles messages or work flows between components of an application.


# Tracking

* Status: Step #1, initial draft


# Analysis

## Message Delivery
Not first in first out with at-least-once semantics.


## Long Polling
Query API supports long polling for efficiency.

Eucalyptus SWF implements long polling, we may be able to re-use the approach for SQS.


## Delay Queues / Message
Message queues support a configurable delay for delivery of messages. Each message can be configured with a specific delay that overrides the default.


## Visibility Timeout
Message queues support a configurable 'visibility timeout', minimum time before redelivery of messages. Each message can be configured with a specific visibility timeout that overrides the default.


## Dead Letter Queues
Dead letter queues can be configured for messages from other queues that are not handled. Messages that are 'received' a certain number of times and not deleted are moved to Dead Letter queues.


## Shared Queues
Queues can be shared between accounts with two approaches.


### Simple API for Shared Queues
Grant and revoke permissions for actions on a queue to specific accounts.


### Advanced API for Shared Queues
Set an IAM resource policy on a queue defining permissions. This can be used to allow anonymous access to a queue by using a wildcard principal.


## CloudWatch Metrics
Metrics for queues are pushed to cloudwatch every 5 minutes.


## Query API
Endpoint identifies the queue. Uses signature v4.


## Interaction with other services
SQS can interact with other services in the following ways.



| Service Name | Interaction | 
|  --- |  --- | 
| SNS | SQS queues can be subscribed to SNS topics, which will publish messages to the SQS queue. This is done in SNS. As SNS is not committed to for 5.0, this is a future interaction. | 
| Cloudwatch | SQS sends metrics to cloudwatch every 5 minutes. This is done on the SQS end. In addition Cloudwatch can trigger alarm actions to post to SNS topics, which could indirectly sendmessages to SQS queues. Again, SNS is not currently slated for 5.0 | 
| CloudFormation | Cloudformation supports the AWS::SQS::Queue and AWS::SQS::QueuePolicy resources. | 
| SWF | No direct interactions (but see long polling, above) | 
| AutoScaling | Lifecycle events (which are not currently supported) can publish to SQS directly. | 
| EC2 | The 'Run' command (not supported) can send status updates to SNS, and CloudTrail (also not supported)can send SNS notifications when new log files are delivered. | 
| ELB | No direct interactions. | 
| IAM | Standard IAM interactions (User based policies that restrict/grant SQS actions), and Resource Based Policy (implemented as Queue Policy in SQS). | 
| S3 | An SQS client library exists allowing 'large messages' to be stored in S3 (see related section below)NotificationConfiguration supports sending messages to SQS directly, as well as SNS topics. | 


## JMS 1.1 Support
Supports JMS point-to-point delivery model. This is achieved via the Amazon SQS Java Messaging Library, which is built on top of the AWS SDK. No additional work is expected to be necessary to use this library with our implementation of SQS, but it should be tested.


## Amazon SQS Extended Client Library for Java
Library that supports large messages via storage in S3. No additional work is expected to be necessary to use this library with our implementation of SQS, but it should be tested.


## Requirements

### Minimum Viable Product
API Actions

| Action | Parameters | Notes | 
|  --- |  --- |  --- | 
| CreateQueue | <ul><li>QueueName</li><li>Attributes: Supported attributes are<ul><li>DelaySeconds

</li><li>MaximumMessageSize</li><li>MessageRetentionPeriod</li><li>ReceiveMessageWaitTimeSeconds</li><li>RedrivePolicy</li><li>VisibilityTimeout</li></ul></li></ul> | All existing SQS Queue Attributes are supported here except for 'Policy'.A queue name may take up to 60 seconds to be available for reuse. Additional Attribute Names exist for GetQueueAttributes, and attempts to use those names will be ignored. AWS notes 'Going forward, new attributes might be added. If you are writing code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.' Testing is required to see if attributes outside the current global attribute list should be ignored or return an error. | 
| DeleteQueue | <ul><li>QueueURL</li></ul> | Delete may take up to 60 seconds to propagate. Messages may still possibly be sent/received during this interval, but no guarantees are made. Amazon AWS may delete queues that are inactive for 30 days. We may wish to pursue a similar policy. | 
| PurgeQueue | <ul><li>QueueURL</li></ul> | As with delete, there may be a 60 second period where these messages can be received, but they will be deleted afterwards. | 
| SetQueueAttributes | <ul><li>QueueURL</li><li>Attributes: Supported attributes are<ul><li>DelaySeconds

</li><li>MaximumMessageSize</li><li>MessageRetentionPeriod</li><li>ReceiveMessageWaitTimeSeconds</li><li>RedrivePolicy</li><li>VisibilityTimeout</li></ul></li></ul> | All existing SQS Queue Attributes are supported here except for 'Policy'.Queue Attributes may take up to 60 seconds to propagate. MesageRetentionPeriod attribute changes can take 15 minutes to become effective. | 
| GetQueueAttributes | <ul><li>QueueURL</li><li>Attributes: Supported attributes are<ul><li>DelaySeconds

</li><li>MaximumMessageSize

</li><li>MessageRetentionPeriod

</li><li>ReceiveMessageWaitTimeSeconds

</li><li>RedrivePolicy,

</li><li>VisibilityTimeout

</li><li>ApproximateNumberOfMessages

</li><li>ApproximateNumberOfMessagesNotVisible

</li><li>ApproximateNumberOfMessagesDelayed

</li><li>CreatedTimestamp

</li><li>LastModifiedTimestamp

</li><li>QueueArn

</li><li>All

</li></ul></li></ul> | AWS notes 'Going forward, new attributes might be added. If you are writing code that calls this action, we recommend that you structure your code so that it can handle new attributes gracefully.' Testing is required to see if attributes outside the current global attribute list should be ignored or return an error. | 
| GetQueueUrl | <ul><li>QueueName</li><li>QueueOwnerAWSAccountId</li></ul> | Subject to permission restrictions. | 
| ListQueues | <ul><li>QueueNamePrefix</li></ul> | At most 1000 queues will be returned. Only queues owned by the calling account will be returned. | 
| ListDeadLetterQueues | <ul><li>QueueURL</li></ul> |  | 
| AddPermission | <ul><li>ActionNames : supported actions are <ul><li>SendMessage</li><li>ReceiveMessage</li><li>DeleteMessage</li><li>ChangeMessageVisibility</li><li>GetQueueAttributes</li><li>GetQueueUrl</li></ul></li><li>AWSAccountIds</li><li>Label</li><li>QueueURL</li></ul> | If a principal has permission to a non-batch operation (such as SendMessage) which has a batch equivalent (such as SendMessageBatch), the principal has permission to the equivalent batch operation. For example, if a principal has permission to 'SendMessage', it also has permission to 'SendMessageBatch' | 
| RemovePermission | <ul><li>Label</li><li>QueueURL</li></ul> |  | 
| SendMessage | <ul><li>DelaySeconds</li><li>MessageAttributes – supported types are<ul><li>Number</li><li>String</li><li>Binary</li></ul></li><li>MessageBody</li><li>QueueURL</li></ul> | TODO: determine if message size limits apply to body or body + message attributes | 
| SendMessageBatch | <ul><li>QueueURL</li><li>SendMessageBatchRequestEntries:<ul><li>DelaySeconds</li><li>Id</li><li>MessageAttributes</li><li>MessageBody</li></ul></li></ul> |  | 
| ReceiveMessage | <ul><li>AttributeNames : supported names are<ul><li>All</li><li>ApproximateFirstReceiveTimestamp</li><li>ApproximateReceiveCount</li><li>SenderId</li><li>SentTimestamp</li></ul></li><li>MaxNumberOfMessages</li><li>MessageAttributeNames</li><li>QueueURL</li><li>VisibilityTimeout</li><li>WaitTimeSeconds</li></ul> | MVP does not require 'Long Polling'. Server may poll. | 
| ChangeMessageVisibility | <ul><li>QueueURL</li><li>ReceiptHandle</li><li>VisibilityTimeout</li></ul> | As with AWS, ReceiptHandles change every time a message is 'Received'. Previous receipt handles should not work. | 
| ChangeMessageVisibilityBatch | <ul><li>ChangeMessageVisibilityBatchRequestEntries:<ul><li>Id</li><li>ReceiptHandle</li><li>VisibilityTimeout</li></ul></li><li>QueueURL</li></ul> |  | 
| DeleteMessage | <ul><li>QueueURL</li><li>ReceiptHandle</li></ul> | As with AWS, ReceiptHandles change every time a message is 'Received'. Previous receipt handles should not work. | 
| DeleteMessageBatch | <ul><li>DeleteMessageBatchRequestEntries: <ul><li>Id</li><li>ReceiptHandle</li></ul></li><li>QueueURL</li></ul> |  | 

PersistenceMessages must be persistent, survive power outages.

IAM supportSQS should support User and Group policies that Allow/Deny access to SQS Actions.

Scalability/ThroughputSQS must support 100 users, each with 100 queues, with 1000 messages per queue, with 500 'in flight' at a given time. (Numbers are subject to change).


### Additional Goals
Queue PoliciesCreateQueue, and Get/SetQueueAttributes should support the 'Policy' attribute. (SQS Queue Policy)

Long PollingReceiveMessage should support long polling.

PersistenceMessages persistence should be implemented in a distributed manner, as in a distributed database.

Scalability/ThroughputSQS must be able to support more users and queues with more hardware. (Horizontally scalable)

CloudWatch MetricsSQS should send the following metrics to Cloudwatch every 5 minutes:


* ApproximateAgeOfOldestMessage
* ApproximateNumberOfMessagesDelayed
* ApproximateNumberOfMessagesNotVisible
* ApproximateNumberOfMessagesVisible
* NumberOfEmptyReceives
* NumberOfMessagesDeleted
* NumberOfMessagesReceived
* NumberOfMessagesSent
* SentMessageSize.

CloudFormation resourcesCloudFormation should support the Queue and QueuePolicy resources.

Euca2ools supportEuca2ools should support API commands mentioned in this document.

Scalability test supportIf possible, some scale testing should be supported. Examples may be found in the Comcast CMB product.

JMS testingIf possible, some testing should be done with our implementation of SQS against the Amazon SQS Java Messaging Library.

S3 extended message testingIf possible, some testing should be done with our implementation of SQS against the Amazon SQS Extended Client Library for Java.


# Use Cases

## Admin Use Cases
Administrators should be able to List and Delete Queues for a given user, as well as Purge Queues.


## User Use Cases
Users should be able to call all API operations and have them act as documented. Clients may include the AWS SDK or euca2ools.


# Elements

# Interactions

# Abstractions

# Milestones
The feature implementation is planned in several phases, details subject to change. Phases do not necessarily map to single sprints.


## Phase 1 (Tracer)
Implement SQS service bindings

Implement Create Queue, Delete Queue, and Purge Queue. Record but ignore queue attributes.

Implement Send Message, Receive Message, and Delete Message. All messages will always be visible, single receipt handles will be generated. No visibility timeout will be supported.

Persistence should be implemented at Level 1 (defined below), enough for the operations described above.


## Phase 2
Implement SetQueueAttributes, GetQueueAttributes, ListQueues, ListDeadLetterQueues.

Implement ChangeMessageVisibility, and honor visibility timeouts, and delay messages, and all queue attributes except Policy.

Implement batch operations.

Support Dead Letter Queues.

Implement new receipt handles on subsequent Receive calls.

Persistence should be implemented at Level 1 (defined below), enough for the operations described above.


## Phase 3
Implement AddPermission and RemovePermission, and honor these values.

Implement CloudWatch metrics.


## Phase 4
Implement persistence at Level 2.

Implement IAM policies. (not resource-level).

Implement Long Polling.


## Phase 5
Implement persistence at level 3.


## Phase 6
Implement support for Queue Policies.


### Persistence Levels
Using Comcast CMB as a reference implementation, different levels of persistence can be achieved for scalability.

Level 1 – Relational DB, presumably on the CLC main host, such as postgres. Quick to implement, but single point of failure.

Level 2 – Distributed database, such as Apache Cassandra. Some partitioning or sharding will likely be necessary to distribute data evenly. However, the cassandra documentation even states that using a database as a queue is an antipattern ([http://www.datastax.com/dev/blog/cassandra-anti-patterns-queues-and-queue-like-datasets](http://www.datastax.com/dev/blog/cassandra-anti-patterns-queues-and-queue-like-datasets)). Comcast CMB remedied this with Level 3.

Level 3 – Distributed database, such as Apache Cassandra, together with a caching mechanism (such as a Redis cluster) to improve read speed.


### Assumptions and Limitations
Cassandra and/or Redis implementations such as Bootstrappers will be completed outside the scope of this effort.

No code changes are assumed to be needed to use the S3 extended SQS library, nor the JMS client library.

Sprint 1


# References

* [[5.0 feature details|SQS]]
* [5.0 Epic](https://eucalyptus.atlassian.net/browse/EUCA-10344)
* [SQS Developer Guide (amazon.com)](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/Welcome.html)
* [SQS API Reference (amazon.com)](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/Welcome.html)





*****

[[tag:confluence]]
[[tag:rls-5.0]]
[[tag:sqs]]
