#Design Document for Scalable Walrus

## Overview
The current Walrus implementation is limited to a single host for servicing S3 requests as well as storing actual user data. This limits the system to scale-up models rather than scale-out. The objective of this design is to achive scale-out capabilities for Walrus in the dimensions of both IO/throughput and storage capacity.

Scalable Walrus is basically a division of the Walrus implementation into two distinct pieces: Object Storage Gateway and multiple back-end providers (Walrus, RiakCS, S3) that provide the persistent storage. The Object Storage Gateway is client-facing and receives, authenticates, and routes requests to the appropriate backend. The Object Storage Gateway is on the data path for all data get/put operations but does not store data directly. It is stateless. The back-end services provide the persistent storage and state management for data objects and user metadata.

## Object Storage Gateway (OSG) Overview
The OSG receives user S3 requests and authenticates and authorizes them using the standard Eucalyptus identity services (EUARE/IAM) as well as the Eucalytus internal account services (currently, the auth DB directly). If a message is accepted as authenticated then it is checked for authorization against IAM policies and if allowed, is dispatched to the appropriate Object Storage Provider (OSP). The interface between the OSG and OSP is still S3 HTTP API.

The OSG is always run in an active/active configuration such that there may be many currently active OSG handling user requests. This mode of operation is independent of that of the OSP, and thus decouples the scale characteristics of the front and back-ends of the system. This is intended for both legacy support (Walrus is active/passive) as well as quick restart and recovery of the front-end components even in the event of complete backend failure. If no OSPs are available the OSGs may still handle requests and simply return 50x errors that the service is unavailable.


## Object Storage Provider (OSP) Overview
The Object Storage Provider is the abstraction of one or more hosts and software components that provide persistent data storage and communicate with clients using an S3-compatible API. It is not required that all S3 operations be supported, but those that are not should return proper 40X errors indicating that the requested operation is invalid/unavailable.

Current OSP implementations: Walrus (non-HA) & Walrus (HA w/DRBD).
Development OSP implementations for 3.4: RiakCS
Future potential OSPs: Ceph, AWS S3, OpenStack Swift.

OSPs may be composed of many hosts or a single host. The minimum requirement is that an OSP is available at a specific URL using the S3 REST API.


## Overall System Functional Design
### User/Client Data Operations
The system should appear as a single S3 storage service to users. This means S3 REST API operations must be supported and the consistency model is 'eventually consistent'.

### Configuration
The system is configurable using a combination of standard Eucalyptus configuration mechansims and concepts including, but not limited to, modifiable properties (e.g. euca-modify-property), the standard eucalytpus.conf configuration file, and service registration (e.g. euca_conf --register-<service>)

Configuration of OSPs may be dependent on the OSP implementation and does not have to conform to Eucalyptus standard mechanisms as of this release although conformance would be ideal to provide a consistent and unified configuration experience.

## Logical Design
###Front-End:
####Input language: S3
####Output language: backend-API (TBD)
####Responsibilities: Receive user request, authenticate, map to proper back-end request.

###Back-End:
####Input language: backend-API (TBD)
####Output language: implementation specific (i.e. CloudFiles/Swift, Raw HTTP, Posix, etc)
####Responsibilities: Manage metadata, receive requests and send/receive data and persist that data in a durable manner.


## External Interfaces
S3 API
Operations on Service: 
* GET
Operations on Buckets: 
* GET
* PUT
* HEAD
* DELETE 
* ?versioning|?logging|?acl
Operations on Objects: 
* GET
* PUT
* HEAD
* DELETE
* ?acl|?versionId

Image API (deprecated)
Snapshot API (deprecated)

## OSG Security Design
### Credential Management for OSPs
Credentials for OSPs are treated as secret information and thus are given the same protections as passwords, private-keys etc. This means:
* No cleartext in DB for credentials
* No cleartext in logs for OSP credentials
* Should not transfer these credentials over the wire in cleartext and any transfer should only be done if strictly necessary. Transfer should be avoided if possible
* OSP credentials for all except the legacy Walrus OSP implementation are considered external credentials.

