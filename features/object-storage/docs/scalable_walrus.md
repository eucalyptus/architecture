#Design Document for Scalable Walrus

## Overview
The current Walrus implementation is limited to a single host for servicing S3 requests as well as storing actual user data. This limits the system to scale-up models rather than scale-out. The objective of this design is to achive scale-out capabilities for Walrus in the dimensions of both IO/throughput and storage capacity.

Scalable Walrus is basically a division of the Walrus implementation into two distinct pieces: Object Storage Gateway and multiple back-end providers (Walrus, RiakCS, S3) that provide the persistent storage. The Object Storage Gateway is client-facing and receives, authenticates, and routes requests to the appropriate backend. The Object Storage Gateway is on the data path for all data get/put operations but does not store data directly. It is stateless. The back-end services provide the persistent storage and state management for data objects and user metadata.

## Object Storage Gateway (OSG) Overview
The OSG receives user S3 requests and authenticates and authorizes them using the standard Eucalyptus identity services (EUARE/IAM) as well as the Eucalytus internal account services (currently, the auth DB directly). If a message is accepted as authenticated then it is checked for authorization against IAM policies and if allowed, is dispatched to the appropriate Object Storage Provider (OSP). The interface between the OSG and OSP is an implementation detail of the OSG plugin used to communicate with the OSP directly.

The OSG is always run in an active/active configuration such that there may be many currently active OSG handling user requests. This mode of operation is independent of that of the OSP, and thus decouples the scale characteristics of the front and back-ends of the system. This is intended for both legacy support (Walrus is active/passive) as well as quick restart and recovery of the front-end components even in the event of complete backend failure. If no OSPs are available the OSGs may still handle requests and simply return HTTP-50X errors that the service is unavailable.

## Object Storage Provider (OSP) Overview
The Object Storage Provider is the abstraction of one or more hosts and software components that provide persistent data storage and communicate with clients using an S3-compatible API. It is not required that all S3 operations be supported, but those that are not should return proper 40X errors indicating that the requested operation is invalid/unavailable.

Current OSP implementations: Walrus (non-HA) & Walrus (HA w/DRBD).
Development OSP implementations for 3.4: RiakCS
Future potential OSPs: Ceph, AWS S3, OpenStack Swift.

OSPs can be composed of many hosts or a single host. The minimum requirement is that an OSP is available at a specific URL using the S3 REST API.

## Overall System Functional Design
The OSG(s) handle *all* client requests. Any client wishing to use Eucalyptus for Object Storage should be configured to connect to the OSG(s) using Eucalyptus user credentials and the S3 API. The OSP is unknown to the end-user and should be considered an internal component of Eucalyptus.

The OSG (as a global entity) is configured to use a specific backend by setting a configurable property: 'euca-modify-property -p osg.backend=[walrus|riakcs|...]'

Additional properties may the require configuration for the specific backend. Examples include: endpoint URI, endpoint credentials, etc. It is expected that a backend be configured prior to configuration of the OSG.

## External Interfaces
* S3 API
* Internal-euca-only Image API (deprecated, subsumed by an independent Image Service)
* Internal-euca-only Snapshot API (deprecated, will be subsumed by S3 API directly)

## OSG Security Design
### Credential Management for OSPs
Credentials for OSPs are treated as secret information and thus are given the same protections as passwords, private-keys etc. This means:
* No cleartext in DB for credentials
* No cleartext in logs for OSP credentials
* Should not transfer these credentials over the wire in cleartext and any transfer should only be done if strictly necessary. Transfer should be avoided if possible
* OSP credentials for all except the legacy Walrus OSP implementation are considered external credentials.

