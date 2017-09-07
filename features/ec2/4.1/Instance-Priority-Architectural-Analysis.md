* [Description](#description)
* [Tracking](#tracking)
* [Analysis](#analysis)
  * [Spot Instance Termination](#spot-instance-termination)
  * [Spot Instance Limits](#spot-instance-limits)
  * [Spot Instances and Usage Reporting](#spot-instances-and-usage-reporting)
  * [Spot Instance Availability / Use](#spot-instance-availability-/-use)
* [Use Cases](#use-cases)
  * [Request Spot Instances](#request-spot-instances)
  * [Request Persistent Spot Instances](#request-persistent-spot-instances)
  * [Resource Administrator Describes Spot Instances](#resource-administrator-describes-spot-instances)
  * [Resource Administrator Terminates Spot Instances](#resource-administrator-terminates-spot-instances)
  * [Account Spot Instance Quota](#account-spot-instance-quota)
  * [User Spot Instance Quota](#user-spot-instance-quota)
  * [Run Instances](#run-instances)
  * [Instance Usage Reporting](#instance-usage-reporting)
  * [Define Spot Instance Resource Pool](#define-spot-instance-resource-pool)
* [Elements](#elements)
  * [Spot Instance Manager](#spot-instance-manager)
  * [Spot Instance Activity Manager](#spot-instance-activity-manager)
* [Workflows & Coordination](#workflows-&-coordination)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
  * [Spot Instance Manager: Spot Instance Request](#spot-instance-manager:-spot-instance-request)
  * [Spot Instance Manager: Spot Instance Request Quota](#spot-instance-manager:-spot-instance-request-quota)
  * [Resource State Manager: Instance Type Availability](#resource-state-manager:-instance-type-availability)
  * [Tag Manager: Spot Instance Request Tag](#tag-manager:-spot-instance-request-tag)
* [Behaviours](#behaviours)
  * [Spot Instance Manager: Spot Instance Request: Create](#spot-instance-manager:-spot-instance-request:-create)
  * [Spot Instance Manager: Spot Instance Request: Describe](#spot-instance-manager:-spot-instance-request:-describe)
  * [Spot Instance Manager: Spot Instance Request: Cancel](#spot-instance-manager:-spot-instance-request:-cancel)
  * [Spot Instance Manager: Spot Instance Request Quota: Evaluate](#spot-instance-manager:-spot-instance-request-quota:-evaluate)
  * [Tag Manager: Spot Instance Request Tag: CRUD](#tag-manager:-spot-instance-request-tag:-crud)
* [References](#references)
* [Notes](#notes)



# Description
As a cloud user, I should be able to mark an instance as a low-priority instance. Such marks would indicate to the administrator (account admin / resource admin / infrastructure admin) that if need be my low-priority instances can be terminated.


# Tracking

* PRD-200
* ARCH-63
* Status: Step #1, initial draft


# Analysis

## Spot Instance Termination
Termination of spot instances occurs due to "certain (agreed upon) conditions". It is assumed that the only reason for spot instance termination is due to capacity contraints, i.e. the resources permitted for spot instance use are exhausted. This may include some capacity "buffer", a configured # or % of free resources (instances of a given type or types)


## Spot Instance Limits
Spot instance limits are distinct from on-demand instance limits, we will have distinct quotas for spot instances.


## Spot Instances and Usage Reporting
Spot instance usage is not billed in AWS/EC2 for partial hours if the instance is terminated by AWS. There is no specific requirement for usage reporting with spot instances for this feature.


## Spot Instance Availability / Use
Running instances will need to propagate that the instance is low priority (spot) to ensure correct provisioning. The cluster controller will need to report availability by instance priority ( spot | on-demand ) to support resource allocation and tracking by the EC2 service.


# Use Cases

## Request Spot Instances
A user requests spot instances be launched in order to perform low priority tasks. Permissions, capacity and quotas are checked to determine if the instances should be launched.


## Request Persistent Spot Instances
A user requests persistent spot instances be launched in order to perform low priority tasks. Permissions, capacity and quotas are checked to determine if the instances should be launched. The spot instance request is re-evaluated periodically to see if instances should be launched until the request (bid) expires.


## Resource Administrator Describes Spot Instances
A resource administrator describes spot (low-priority) instances using a filter.


## Resource Administrator Terminates Spot Instances
A resource administrator identifies and terminates spot (low-priority) instances.


## Account Spot Instance Quota
A resource administrator limits the number of spot instances available to an account.


## User Spot Instance Quota
An account admin limits the number of spot instances available to a user in the account.


## Run Instances
A user launches instances, spot instances are terminated to free capacity.


## Instance Usage Reporting
An administrator generates a report on instance usage. Spot instance usage is included with regular (on-demand) instance usage including partial hours in which the instance was terminated by the cloud.


## Define Spot Instance Resource Pool
An infrastructure administrator defines a pool of resources for spot instance usage.


# Elements

## Spot Instance Manager
The spot instance manager implements EC2 API actions related to spot instances.


## Spot Instance Activity Manager
Responsible for spot instance lifecycle.

![](images/architecture/spot.png)


# Workflows & Coordination
![](images/architecture/spot-comm.png)


# Interactions
EC2 User -> Spot Instance Manager : EC2 API actions for spot instance management

Spot Instance Activity Manager -> VM Control : Launches and terminates instances

Resource State Manager > Cluster Controller : Queries for current and maximum availability by instance type, platform and priority (spot / on-demand)


# Abstractions

## Spot Instance Manager: Spot Instance Request
Represents a request for spot instances.


## Spot Instance Manager: Spot Instance Request Quota
A quota on the number of spot instances requested.


## Resource State Manager: Instance Type Availability
Represents availability of an instance type by platform, priority and availability zone.


## Tag Manager: Spot Instance Request Tag
A tag for a spot instance request.


# Behaviours

## Spot Instance Manager: Spot Instance Request: Create
Spot instances are requested by a user. The request is persisted and the spot instance activity manager later processes the request, updating the status (etc)


## Spot Instance Manager: Spot Instance Request: Describe
A user describes the spot instance requests for their account.


## Spot Instance Manager: Spot Instance Request: Cancel
A user cancels spot instance requests.


## Spot Instance Manager: Spot Instance Request Quota: Evaluate
Quotas are evaluated when spot instance requests are created.


## Tag Manager: Spot Instance Request Tag: CRUD
EC2 actions related to tagging, not specific to spot instance request tags.


# References

* [Spot instances (docs.aws.amazon.com)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)


# Notes

* Need use case for spot instance minimum time? (does AWS/EC2 have this?)
* Need use case for spot instance resource pool utilization report? (along the lines of "euca-describe-instance-types --show-capacity")



*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:ec2]]
