* [Description](#description)
* [Tracking](#tracking)
* [Use Cases](#use-cases)
  * [Account Quota](#account-quota)
  * [User Quota](#user-quota)
  * [Start / Run Instances](#start-/-run-instances)
* [Elements](#elements)
  * [Instance Resource Tracker](#instance-resource-tracker)
  * [Instance Resource Quota Evaluator](#instance-resource-quota-evaluator)
* [Interactions](#interactions)
  * [IAM User -> Policy Manager](#iam-user-->-policy-manager)
  * [Instance Allocator -> Policy Engine](#instance-allocator-->-policy-engine)
  * [Policy Engine -> Instance Resource Quota Evaluator](#policy-engine-->-instance-resource-quota-evaluator)
  * [Instance Resource Quota Evaluator -> Resource State Manager](#instance-resource-quota-evaluator-->-resource-state-manager)
  * [Instance Resource Quota Evaluator -> Instance Resource Tracker](#instance-resource-quota-evaluator-->-instance-resource-tracker)
  * [Instance Resource Tracker -> Cluster Controller](#instance-resource-tracker-->-cluster-controller)
* [Abstractions](#abstractions)
  * [Node: Instance](#node:-instance)
  * [Resource State Manager: Resource Token](#resource-state-manager:-resource-token)
  * [Instance Resource Tracker: Resource](#instance-resource-tracker:-resource)
  * [Instance Resource Quota Evaluator: Instance Resource Quota](#instance-resource-quota-evaluator:-instance-resource-quota)
* [Behaviours](#behaviours)
  * [Policy Manager: Policy: Create](#policy-manager:-policy:-create)
  * [Policy Manager: Policy: Delete](#policy-manager:-policy:-delete)
  * [Instance Resource Tracker: Resource: Refresh](#instance-resource-tracker:-resource:-refresh)
  * [Instance Resource Tracker: Resource: Query](#instance-resource-tracker:-resource:-query)
  * [Instance Resource Quota Evaluator: Instance Resource Quota: Evaluate Usage](#instance-resource-quota-evaluator:-instance-resource-quota:-evaluate-usage)
  * [Instance Resource Quota Evaluator](#instance-resource-quota-evaluator)



# Description
As a cloud resource administrator, I should be able to specify quotas and policies on the number of CPUs, RAM and disk space, so that my users have more flexibility in how they will utilize their quota across the different instance types.


# Tracking

* PRD-215
* ARCH-61
* Status: Step #1, initial draft


# Use Cases

## Account Quota
A cloud account administrator restricts the resources available to an account in terms of CPU, RAM and disk. The restricting quota statement is contained in a policy attached to the restricted account. The quota statement can be seen when describing the containing policy.


## User Quota
An accounts admin user restricts the resources available to a user in terms of CPU, RAM and disk. The restricting quota statement is contained in a policy attached to the restricted user. The quota statement can be seen when describing the containing policy.


## Start / Run Instances
A cloud user requests start / runs of X instances. Quotas are evaluated to determine resource availability for the instances, account and user quotas are evaluated. Policy evaluation checks the resources currently in use plus the resources requested against any limits and fails the request if sufficient resources are not available in the region.


# Elements

## Instance Resource Tracker
The instance resource tracker tracks resources usage for instances. Instances reference their instance type but this may no longer relate to the resources in use by an instance.


## Instance Resource Quota Evaluator
Evaluates instance resource quotas, determining the requested resources using current instance type information and existing resource usage via the instance resource tracker.

![](images/architecture/compute-resource-policy.png)


# Interactions

## IAM User -> Policy Manager
Creates IAM policies and attaches to an account or user. Policies are broken down into Authorizations for later use in policy evaluation.


## Instance Allocator -> Policy Engine
For each requested resource type (CPU, disk, RAM) resource quotas are evaluated, the resource quantity is determined by the instance type and count.


## Policy Engine -> Instance Resource Quota Evaluator
When the policy engine evaluates a resource quota, the instance resource quota evaluator is used to obtain the current resource usage which is then compared against the quota.


## Instance Resource Quota Evaluator -> Resource State Manager
Queries in-flight resource usage for CPU, disk or RAM resources for the relevant scope (user or account)


## Instance Resource Quota Evaluator -> Instance Resource Tracker
Resource usage for CPU, disk or RAM resources is obtained from the Instance Resource Tracker for the relevant scope (user or account)


## Instance Resource Tracker -> Cluster Controller
Describes instances to determine resources used. Records usage by user/account for use during quota evaluation.


# Abstractions

## Node: Instance
Node controller representation of an instance, including that instances resource usage in terms of CPU, RAM and disk via the (historical) instance type definition.


## Resource State Manager: Resource Token
Record of resources that have been allocated but may not yet be known outside of the EC2 service.


## Instance Resource Tracker: Resource
Instance resource trackers record of resources used by instance obtained from the owning node.


## Instance Resource Quota Evaluator: Instance Resource Quota
A quota for an instance resource.


# Behaviours

## Policy Manager: Policy: Create
Create a policy containing a quota.


## Policy Manager: Policy: Delete
Delete a policy containing a quota.


## Instance Resource Tracker: Resource: Refresh
Refresh resources used for a cluster


## Instance Resource Tracker: Resource: Query
Query the resources in use by a user or account


## Instance Resource Quota Evaluator: Instance Resource Quota: Evaluate Usage
Evaluate the current usage for a resource.


## Instance Resource Quota Evaluator


*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:ec2]]
