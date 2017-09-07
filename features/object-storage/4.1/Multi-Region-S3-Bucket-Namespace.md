 **Overview** As a user I would like to interact with multiple Eucalyptus clouds and object stores in a way that is consistent with the semantics and behavior of AWS S3 so that my tools and logic are consistent and I can access logically distinct object stores for redundancy, geodistribution/locality, and performance optimization.

 **Assumptions/Pre-requisites** The total set of accounts across all regions must be available via some service. Only single element lookup is required.

Regions must be able to authenticate/communicate with each other as “system” users. User-identity federation/sync is required for data operations (cross-region copy), but system-level is also required for synchronization operations.

 **Functional Requirements** 
* Buckets identified uniquely by name across multiple regions.
* Any bucket is present in exactly 1 region and its name resolves by DNS to exactly 1 DNS name
* Creation of a bucket will fail if the name already exists in any region (failure may mean transparent success but no new bucket is created, per S3 spec)
* S3 Location constraints are enforced
* Location constraint much match the endpoint used for bucket creation
* S3 API requests for a bucket that are directed to any region other than the region hosting the bucket must result in a 307 Permanent Redirect to the proper region being returned to the client
* Deletion of a bucket must make that name available for creation in any region
* Bucket creation/deletion is relatively low-frequency and is not highly performance sensitive. Second-level latencies are okay under load. Bucket operations are not considered hot-path operations.
* System must handle O(seconds) latency on inter-region links (think latency from US->China or US->India)

 **Domain Model:** 
* Bucket — A logical container for object names and configuration
* Region — A set of S3 endpoints (typically of size 1, but may be addressable in multiple ways…e.g. service path vs no service path + DNS)
* Bucket \*->1 Region

 **Architecture Components** Bucket Name Reservation System
1. Global consensus to reserve a name for a specific region
1. Reserved state: name->region mapping
1. Total state: set of name->region relations
1. Persistent, resilient to region failure
1. Implementation options:
    1. Use 3rd party consensus/data store system (e.g. risk-enterprise, cassandra)
    1. Build into Eucalyptus directly using Paxos/Distributed Commit(2PC, etc) backed by region-local data store
    1. Will require API, new service for implementing the distributed consensus

    
    1. Requires: region group & quorum management

    

Eucalyptus OSG
* On bucket create
    * Validate location constraint is correct for the region
    * Reserve name
    * Create bucket

    
* On bucket delete:
    * Delete bucket
    * Remove reservation to free the name

    
* On bucket operation/lookup
    * Lookup bucket locally, if failure, lookup reservation and return redirect to proper region

    



*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:object-storage]]
