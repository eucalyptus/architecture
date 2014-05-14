#Design Document for Scalable Object Storage (introduced in Eucalyptus 4.0)

## Overview
The current Walrus implementation is limited to a single host for servicing S3 requests as well as storing actual user data. This limits the system to scale-up models rather than scale-out. The objective of this design is to achive scale-out capabilities for Walrus in the dimensions of both IO/throughput and storage capacity.

Scalable Walrus is basically a division of the Walrus implementation into two distinct pieces: Object Storage Gateway and multiple back-end providers (Walrus, RiakCS, S3) that provide the persistent storage. The Object Storage Gateway is client-facing and receives, authenticates, and routes requests to the appropriate backend. The Object Storage Gateway is on the data path for all data get/put operations but does not store data directly. It is stateless. The back-end services provide the persistent storage and state management for data objects and user metadata.

## System components
The Scalable Object Storage is composed of the following components:
* Object Storage Gateway (OSG) - Mulitplicity: many. This is the S3 API endpoint(s) that take user requests, manage metadata as needed, and dispatch requests to the OSP(s) to store/retrieve data.
* Object Storage Provider (OSP) - Multiplicity: many. This component (not necessarily part of Eucalyptus itself), is responsible for storing, retrieving, deleting, updating the object and bucket data.
* Database/Metadata persistence - Multiplicity: up to 2 (as of Eucalyptus 4.0). Object storage leverages the standard Eucalyptus database system (PostgreSQL + Hibernate) for the persistence of system metadata.
* Identity management - The standard Eucalyptus IAM implementation accessed via internal libraries. This is opaque to external users. All identities are managed by Eucalyptus IAM, not the Object Storage system iteslf.

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
Client->OSG:
* S3 API, exclusively. REST only supported. No S3 SOAP support.

OSG->OSP:
* Any API, but must support CRUD operations on objects and buckets

## OSG Security Considerations
### Credential Management for OSPs
Credentials for OSPs are treated as secret information and thus are given the same protections as passwords, private-keys etc. This means:
* No cleartext in DB for credentials
* No cleartext in logs for OSP credentials
* Should not transfer these credentials over the wire in cleartext and any transfer should only be done if strictly necessary. Transfer should be avoided if possible
* OSP credentials for all except the legacy Walrus OSP implementation are considered external credentials.

### Securiting network communications
SSL/HTTPS with certificate validation is the primary mechanism for security network communications to/from the OSG. This applies to both client operations to the OSG as well as OSG operations to the backend OSP.
This is configured using properties in Eucalyptus:
* objectstorage.s3provider.usebackendhttps -- Configures the backend provider for S3 compatible backends (Walrus/RiakCS/Ceph) to use HTTPS for operations from the OSG->OSP

### Securing data at rest


## Configuration of Object Storage
### Selecting the OSP
* objectstorage.providerclient=[walrus|riakcs|ceph]

### Configuring the OSG(s)
* objectstorage.queue_size=[number of chunks to buffer before declaring timeout] -- Sets the amount of 100K data buffers that the OSG will allow to be kept before failing a PUT operation because the data is not being transfered to the OSP quickly enough relative to the sender
* objectstorage.bucket_creation_wait_interval_seconds=[seconds to wait max for bucket creation on OSP] -- Controls the amount of time a bucket can be in the 'creating' state awaiting a response from the OSP. This is typically only used to cleanup metadata in the DB in the case where an OSG fails mid-operation and cannot complete the state update for the bucket
* objectstorage.bucket_naming_restrictions=[dns-compliant|extended] -- Determines how the OSG will validate bucket names during bucket creation. 'dns-compliant' is strict DNS compliance and S3 compatible for non-US-Standard regions. 'extended' is the naming scheme that includes extra, non-dns characters as implemented by S3's US-Standard region.
* objectstorage.cleanup_task_interval_seconds=[seconds between cleanup tasks, default=60] -- Time between cleanup task executions that clear buckets/objects that were not fully uploaded or failed state due to OSG failures.
* objectstorage.dogetputoncopyfail=[true|false] -- Sets the OSG to use GET-then-PUT if the OSP does not support object copy operations natively.
* objectstorage.failed_put_timeout_hrs=[# of hours to allow an object to remain in 'creating' state before deciding it has failed, default=168] -- Used to determine, if all other methods fail, when to time-out a PUT operation
* objectstorage.max_buckets_per_account	100
* objectstorage.max_total_reporting_capacity_gb=[some number of GBs, default: 2147483647] -- This is the number used for reporting capacity usage. This does NOT limit or restrict usage, only for reporting % usage as (total stored)/(reporting capacity). This may result in usage being > 100% in the Eucalyptus reporting system.


### Configuring OSPs


