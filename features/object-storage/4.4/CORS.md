

* [Description](#description)
* [Tracking](#tracking)
* [Related Features](#related-features)
    * [eucaconsole](#eucaconsole)
* [Related Issues](#related-issues)
* [Analysis](#analysis)
* [Use Cases](#use-cases)
  * [Admin Use Cases](#admin-use-cases)
    * [Initial Setup](#initial-setup)
  * [User Use Cases](#user-use-cases)
* [Assumptions and Questions](#assumptions-and-questions)
* [Elements](#elements)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
    * [CORS Configuration](#cors-configuration)
    * [CORS Rule](#cors-rule)
    * [CORS Configuration Access](#cors-configuration-access)
    * [CORS Preflight Request](#cors-preflight-request)
    * [CORS Access Request](#cors-access-request)
* [Milestones](#milestones)
* [Risks](#risks)
* [References](#references)



# Description
 _(Adapted from AWS CORS Dev Guide)_ Cross-origin resource sharing (CORS) defines a way for client web applications that are loaded in one domain to interact with resources in a different domain. With CORS support in S3, you can build rich client-side web applications with S3 and selectively allow cross-origin access to your S3 resources. 

We wish to support the S3 CORS feature in Eucalyptus. We expect it to be fully compatible with the AWS CORS feature. 

The Eucalyptus web console can use this as well as any user-created browser-based application that is subject to CORS constraints.




# Tracking

1. Aug 2016: Initial template
1. Sep 2016: First draft, in progress


# Related Features

### eucaconsole
The Management Console will be adding support for CRUD operations on a bucket's CORS configuration, to be implemented by [GUI-2735 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/GUI-2735).


# Related Issues
[EUCA-12174 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-12174)


# Analysis



# Use Cases

## Admin Use Cases

### Initial Setup
TBD


## User Use Cases

# Assumptions and Questions
Assumptions and open questions around requirements for the feature.

Assumptions:

Open questions:


# Elements

# Interactions

# Abstractions

### CORS Configuration
A set of CORS Rules that define which other domains can access which resources in a given bucket in what ways


### CORS Rule
A definition of a set of origins that can access certain resources in a given bucket in certain ways


### CORS Configuration Access
An HTTP request to an S3 endpoint to perform CRUD operations on a CORS Configuration


### CORS Preflight Request
An HTTP request to find out if an access attempt to an S3 resource in a different domain would succeed


### CORS Access Request
An HTTP request to access an S3 resource in a different domain from the requesting origin.


# Milestones
See [EUCA-12715 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-12715) for details.


# Risks
Areas currently identified as risks:

AWS returns CORS headers in responses for any S3 request, whether it's relevant to that request or not. That covers a lot of touch points in Eucalyptus code, if we want to be fully compatible.


# References

* [[CORS feature details|CORS-Configuration-for-S3-Buckets]]
* [Amazon Simple Storage Service Developer Guide](http://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html)



*****

[[tag:confluence]]
[[tag:rls-4.4]]
[[tag:object-storage]]
[[tag:cors]]
