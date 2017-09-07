* [Description](#description)
* [Tracking](#tracking)
* [Analysis](#analysis)
  * [General](#general)
    * [Reservation Granularity](#reservation-granularity)
    * [Reserved Instance Quota](#reserved-instance-quota)
    * [Product Description](#product-description)
    * [Instance Type Modification](#instance-type-modification)
  * [EC2 Reserved Instances Gap](#ec2-reserved-instances-gap)
    * [Running Reserved Instance](#running-reserved-instance)
    * [Running Instance with Reservation](#running-instance-with-reservation)
    * [](#)
* [Use Cases](#use-cases)
  * [Define Reserved Instance Offerings](#define-reserved-instance-offerings)
  * [Reserve Instances](#reserve-instances)
  * [Reserved Instances Expire](#reserved-instances-expire)
  * [Reserved Instance Offering Updates](#reserved-instance-offering-updates)
  * [Check Reserved Instance Usage](#check-reserved-instance-usage)
  * [AccountReserved Instance Limitation](#accountreserved-instance-limitation)
  * [Configure Resource Pool for Windows Instances](#configure-resource-pool-for-windows-instances)
  * [Run Windows Instance](#run-windows-instance)
* [Elements](#elements)
  * [Reservation Manager](#reservation-manager)
* [Workflows & Coordination](#workflows-&-coordination)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
  * [Reservation Manager: Reserved Instances Offering](#reservation-manager:-reserved-instances-offering)
  * [Reservation Manager: Instance Reservation](#reservation-manager:-instance-reservation)
  * [Resource State Manager: Instance Type Availability](#resource-state-manager:-instance-type-availability)
* [Behaviours](#behaviours)
  * [Reservation Manager: Reserved Instances Offering: Create](#reservation-manager:-reserved-instances-offering:-create)
  * [Reservation Manager: Reserved Instances Offering: Delete](#reservation-manager:-reserved-instances-offering:-delete)
  * [Reservation Manager: Reserved Instances Offering: Describe](#reservation-manager:-reserved-instances-offering:-describe)
  * [Reservation Manager: Reserved Instance Offering: Purchase](#reservation-manager:-reserved-instance-offering:-purchase)
  * [Reservation Manager: Instance Reservation: Describe](#reservation-manager:-instance-reservation:-describe)
  * [Resource State Manager: Instance Type Availability: Refresh](#resource-state-manager:-instance-type-availability:-refresh)
  * [Resource State Manager: Instance Type Availability: Query](#resource-state-manager:-instance-type-availability:-query)
* [References](#references)



# Description
As a cloud resource administrator, I would like to be able to reserve capacity (cores / memory / disk) on a per account basis, so that specific accounts get a guaranteed minimum capacity (reservation) at any given point in time.


# Tracking

* PRD-199
* ARCH-64
* Status: Step #1, initial draft


# Analysis
The aim is to cover the required functionality via implementation of EC2 reserved instances and placement groups.


## General

### Reservation Granularity
It is not meaningful to reserve capacity for (cores / memory / disk) as you do not launch instances by specifying fine grained resources but by specifying an instance type. An instance type may also have additional constraints besides the (cores / memory / disk) resource requirements.


### Reserved Instance Quota
The default limit for reserved instances in AWS/EC2 is "20 instance reservations per Availability Zone, per month", we may need to be able to restrict reserved instances via Quota or other approach.


### Product Description
An instance reservation relates to a product as well as an instance type. We can use the product description to map reservations onto resource pools.


### Instance Type Modification
If resource reservations are for particular instance types then this conflicts with instance type modification, as changing the types could mean that additional capacity must be reserved (which may not be available)


## EC2 Reserved Instances Gap
Differences between requirements and EC2 reserved instances functionality.


### Running Reserved Instance
There is no such thing as a running reserved instance. An instance reservation is the option to run an instance, when exercised the result is an instance (like any other instance). It does not make sense to have a pool of resources for reserved instances, as by definition a reserved instance is never running.


### Running Instance with Reservation
When an instance reservation matches the parameters of a run instance request the reservation is automatically utilized, any (matching) on-demand instance can be utilizing the reservation. It does not make sense to run an instance "outside" of the reservation, the reservation is a block of capacity, any instance uses capacity and so uses the reservation.


### Utilization
AWS/EC2 reserved instances specify a utilization level (light, medium, heavy), this concept is not meaningful in the absence of billing.


# Use Cases

## Define Reserved Instance Offerings
A cloud infrastructure administrator defines the instances / instance types available for reservation.


## Reserve Instances
A cloud user lists reserved instance offerings and reserves instances of the desired type.


## Reserved Instances Expire
The term for some reserved instances expires. Instances continue to run and the reserved instances are not available as offerings until they terminate.


## Reserved Instance Offering Updates
On-demand instances are launched, utilizing capacity covered by a reserved instance offering. The reserved instance offerings update to reflect the available capacity.


## Check Reserved Instance Usage
A cloud user checks their running instances against their reservations to determine usage.


## AccountReserved Instance Limitation
A resource administrator limits the number of reserved instances available to an account.


## Configure Resource Pool for Windows Instances
An infrastructure administrator configures particular nodes available capacity for use with windows instances.


## Run Windows Instance
A user launches a windows instance, it is provisioned to run on resources that are licensed for such instances.


# Elements

## Reservation Manager
The reservation manager implements EC2 API actions related to reserved instances and provides access to reservation information for use when allocating resources.

![](images/architecture/reservation.png)


# Workflows & Coordination
![](images/architecture/reservation-comm.png)


# Interactions
Instance Allocator -> Resource State Manager : Reserves resources for running instances

Resource State Manager -> Reservation Manager : Queries current reservations by instance type and platform

Resource State Manager -> Cluster Controller : Queries for current and maximum availability by instance type and platform

Reservation Manager -> Resource State Manager : Queries availability to ensure capacity for new / modified reservations

EC2 User -> Reservation Manager : Performs EC2 API actions

Administrator -> Reservation Manager : Sets up initial reservations for accounts


# Abstractions

## Reservation Manager: Reserved Instances Offering
An offering of reserved instances (by instance type, platform and availability zone)


## Reservation Manager: Instance Reservation
Represents a number of reserved instances (as per EC2)


## Resource State Manager: Instance Type Availability
Represents availability of an instance type by platform and availability zone.


# Behaviours

## Reservation Manager: Reserved Instances Offering: Create
A resource administrator creates a reserved instances offering \[for an account?]


## Reservation Manager: Reserved Instances Offering: Delete
A resource administrator deletes a reserved instances offering.


## Reservation Manager: Reserved Instances Offering: Describe
A user or administrator describes reserved instance offerings.


## Reservation Manager: Reserved Instance Offering: Purchase
A user purchases a reserved instances offering (purchase is the activity, but there is no associated cost)


## Reservation Manager: Instance Reservation: Describe
A user describes their reserved instances.


## Resource State Manager: Instance Type Availability: Refresh
Instance type availability is refreshed by platform and availability zone (cluster)


## Resource State Manager: Instance Type Availability: Query
Instance type availability is queried to see if instances can be run.


# References

* [Reserved instances (docs.aws.amazon.com)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts-on-demand-reserved-instances.html)
* [Utility to check reserved instance usage (github.com/epheph)](https://github.com/epheph/ec2-check-reserved-instances)





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:ec2]]
