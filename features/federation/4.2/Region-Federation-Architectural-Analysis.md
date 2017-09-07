* [Description](#description)
* [Tracking](#tracking)
* [Analysis](#analysis)
  * [Account Creation](#account-creation)
  * [Lookup By Credentials](#lookup-by-credentials)
* [Use Cases](#use-cases)
  * [Admin Use Cases](#admin-use-cases)
  * [User Use Cases](#user-use-cases)
* [Elements](#elements)
  * [IAM Authentication Service](#iam-authentication-service)
  * [IAM Home Region Interceptor](#iam-home-region-interceptor)
  * [IAM Region Configuration Manager](#iam-region-configuration-manager)
  * [Policy Cache](#policy-cache)
  * [Authentication Cache](#authentication-cache)
  * [IAM Global Information Manager](#iam-global-information-manager)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
* [Milestones](#milestones)
  * [Sprint 1](#sprint-1)
* [References](#references)



# Description
 **_Identity Federation_**  means that a Cloud Administrator can create a  **_federation_** of (otherwise independent) Eucalyptus "clouds" where a Cloud User, using the same credentials as always, can use any of these federated Eucalyptus cloud  **_regions_** . For the parts of IAM & STS that Eucalyptus implements, the experience exposed to the Cloud User is the same as that seen by an AWS user working across AWS regions.


# Tracking

* Status: Step #1, initial draft


# Analysis
See Zach's [[Thoughts on region/identity federation and multi-region support|Thoughts-on-region-identity-federation-and-multi-region-support]] and additional info on identifier partitioning in [ARCH-112](https://eucalyptus.atlassian.net/browse/ARCH-112).


## Account Creation
We currently require an account alias to be specified at account creation time. An alias is not required for an account and removing this requirement would allow accounts to be created with no impact on other regions (so could be permitted in the event of network partition if other identifiers were partitioned)


## Lookup By Credentials
For X.509 authentication it would be useful to follow the AWS/IAM approach of deriving signing certificate identifiers from the X.509 certificate so that a lookup by identifier is possible.


# Use Cases

## Admin Use Cases

* Configure Region to be Federated with another Region
    * Configure  _this_  region to  _trust another region_  for purposes of authentication (establish trusted provider relationship)
    * Configure  _this_ region to  _allow another region_  to use it for purposes of authentication (establish relying party relationship)

    
* Delete Region's federation relationship with another region

    
    * Delete this region's trust provider relationship with another region
    * Delete this region's relying party relationship with another region

    
* Describe Regions (with Federation information)
    * Status, Credentials establishing trust

    


## User Use Cases

* User is trying to perform  _SomeOperation_ (any operation) against
    * First, an initial region (lets say it is the region of record for the user's identity)
    * Second, another region which is federated with the initial region

    


# Elements

## IAM Authentication Service
Internal authentication / policy service


## IAM Home Region Interceptor
Intercepts IAM/STS requests and dispatches to the right region


## IAM Region Configuration Manager
Manages configuration and mapping identifiers to regions


## Policy Cache
Caches versions of policies


## Authentication Cache
Caches credentials, principals and policy identifiers


## IAM Global Information Manager
Helper for global info updates

![](images/architecture/identity-federation.png)


# Interactions

# Abstractions

# Milestones

## Sprint 1

# References

* 4.2 [[feature details|Identity-Federation]]
* 4.2 [epic](https://eucalyptus.atlassian.net/browse/EUCA-10334)
* Previous incomplete [[architectural analysis|Region-Federation-(Arch.-Analysis)]] from 4.1
* Zach's [[Thoughts on region/identity federation and multi-region support|Thoughts-on-region-identity-federation-and-multi-region-support]]





*****

[[tag:confluence]]
[[tag:rls-4.2]]
[[tag:federation]]
