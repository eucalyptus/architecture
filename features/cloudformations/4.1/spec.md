

* [Description](#description)
* [Tracking](#tracking)
* [Analysis](#analysis)
* [Use Cases](#use-cases)
  * [Create Stack](#create-stack)
  * [Delete Stack](#delete-stack)
  * [Update Stack](#update-stack)
  * [Cancel Update Stack](#cancel-update-stack)
  * [Describe/List Stack](#describe/list-stack)
  * [Describe/List Stack Resource(s)](#describe/list-stack-resource(s))
  * [Describe Stack Events](#describe-stack-events)
  * [Validate Template](#validate-template)
    * [TODO: Do we need to enumerate handling all different resource types?](#todo:-do-we-need-to-enumerate-handling-all-different-resource-types?)
* [Elements](#elements)
  * [Cloud Formation Service](#cloud-formation-service)
  * [Template Parser](#template-parser)
  * [Function Evaluator](#function-evaluator)
  * [Stack Entity Manager](#stack-entity-manager)
  * [Stack Resource Entity Manager](#stack-resource-entity-manager)
  * [Stack Event Entity Manager](#stack-event-entity-manager)
  * [Dependency Manager](#dependency-manager)
  * [Resource Manager](#resource-manager)
  * [Workflow Manager](#workflow-manager)
* [Workflows & Coordination](#workflows-&-coordination)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
* [Behaviours](#behaviours)
* [References](#references)
* [Notes](#notes)



# Description
As a cloud user, I would like to use AWS Cloudformation templates in the system, so I don't have to repeatedly create multi-layered applications by hand.

As a cloud user, I would like support for additional Cloudformation resource types than were done in 4.0, including S3 Resources, and whatever resources are necessary to enable AWS::CloudFormation::CloudInit (AWS::Cloudformation::WaitCondition)

As a cloud user, I would like to be able to delete a stack that is being created.


# Tracking
[PRD-93 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/PRD-93)

[PRD-94 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/PRD-94)

[ARCH-69 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/ARCH-69)


# Analysis
TODO


# Use Cases

## Create Stack
A user initiates a Create Stack request based on a template and other input parameters.


## Delete Stack
A user initiates a Delete Stack request.


## Update Stack
A user initiates an Update Stack request based on a template and other input parameters.


## Cancel Update Stack
A user initiates an Cancel Update Stack request


## Describe/List Stack
A user initiates a describe request for Stack information. (API calls are DescribeStack or ListStack)


## Describe/List Stack Resource(s)
A user initiates a describe request for Resource information about a given stack.. (API calls are DescribeStackResource, DescribeStackResources or ListStackResources)


## Describe Stack Events
A user initiates a describe request for events related to a given stack.


## Validate Template
A user initiates a request to validate a template.


### TODO: Do we need to enumerate handling all different resource types?

# Elements

## Cloud Formation Service
A REST/Query API implementation of the AWS Cloud Formation API. Responsible for user initiated Stack CRUD operations. (Create/Update/DeleteStack and List/Describe)(Stack)\* operations, as well as validate template).


## Template Parser
Parses JSON templates, converts them into appropriate object representation.


## Function Evaluator
Determines whether a given JSON object represents a Cloud Formation "function", validates argument types where possible, and evaluates the function, given resource, parameter, and system data as inputs.


## Stack Entity Manager
Manages CRUD operations for Stack Entity objects, which represent the state of stacks as a whole.


## Stack Resource Entity Manager
Manages CRUD operations for Stack Resource Entity objects, which represent the state of resources within a stack.


## Stack Event Entity Manager
Manages CRUD operations for Stack Event Entity objects, which represent the events that have occurred during the lifetime of a stack. (Stack and Stack Resource state values)


## Dependency Manager
Given a series of resource dependencies, perform a topological sort to determine the correct creation order of events. May need to reverse the order during delete or rollback.


## Resource Manager
Manages CRUD operations for an actual Resource (such as Instance, Volume, etc). Each Resource Type will need to implement several classes for the Resource Manager to act on.


## Workflow Manager
Manages current running workflows which perform Stack CRUD operations. Each workflow in SWF should have an id which can be used for cancellation, for example.



TODO: Missing: Resource breakdown into Properties (ResourceProperties) Actions (SWF Activities for create/delete/update, etc) (ResourceActions), and everything else (function "outputs" if you will (ResourceAttributes) and things like whether or not it supports Snapshots, possibly update info)

TODO: Also missing details of template parsing, and serialization of objects)


# Workflows & Coordination

# Interactions
EC2 User -> Cloud Formation Service : Cloud Formation API actions

Cloud Formation Service -> Template Parser: Parses template before stack modification operations occur.

Cloud Formation Service -> Workflow Manager: Kicks off workflows for stack creation, deletion, update, or cancellation.

Template Parser -> Function Evaluator: Evaluates functions as part of template evaluation

Template Parser -> Dependency Manager : Determines resource order once dependency order is determined.

Resource Manager-> Function Evaluator : Once other resources are created, resource properties are recomputed with function references to other resources.

Function Evaluator-> Stack Resource Entity Manager : Function evaluation may require resource properties to evaluate the 'Ref' function.

Stack Entity Manager -> Entities : perform CRUD operations

Stack Resource Entity Manager -> Entities : perform CRUD operations

Stack Event Entity Manager -> Entities : perform CRUD operations

Workflow Manager -> Stack Entity Manager : Update stack state during Stack CRUD operations.

Workflow Manager -> Stack Event Entity Manager : Create new events during stack or resource state change.

Resource Manager -> Stack Resource Entity Manager: Update resource state during Resource CRUD operations

Resource Manager -> External MSGS service or AWS SDK client to send CRUD commands for Resources.

Workflow Manager -> Resource Manager: Create resources one at a time during Stack Create, delete during delete, etc.




# Abstractions



# Behaviours

# References

# Notes


*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:cloudformations]]
