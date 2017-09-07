* [Description](#description)
* [Tracking](#tracking)
* [Status](#status)
  * [VPC Networking](#vpc-networking)
  * [Edge Networking](#edge-networking)
  * [Cluster Controller](#cluster-controller)
  * [Block Storage Controller](#block-storage-controller)
  * [Object Storage Gateway](#object-storage-gateway)
  * [Console](#console)
  * [Cloud Controller](#cloud-controller)
* [Proposals](#proposals)
  * [VPC Networking](#vpc-networking)
  * [Edge Networking](#edge-networking)
  * [Approaches and Dependencies](#approaches-and-dependencies)
  * [Related Areas and Concerns](#related-areas-and-concerns)
* [References](#references)



# Description
Status, proposals and (5.0) priorities related to availability.


# Tracking

* Status: Step #1, initial draft


# Status

## VPC Networking

* midonet availability
    * network state available database ( zookeeper / cassandra )
    * network traffic gateways, multiple for redundancy (up to 6) - for both availability and load balancing

    
* API (tomcat) is single point of failure - keystone required for authenticated access (v1.9), may have changed in 5.0
* eucanetd is single point of failure (CLC colocated) - no channel for error conditions
* instance metadata is single point of failure (nginx, related networking)
* no general networking path from instances to cloud. DNS would have similar issues to instance metadata


## Edge Networking

* cluster controller availability / network broadcast
* changes to broadcast could impact instance gating


## Cluster Controller

* cluster is a stateless component so persistence not an issue
* more issues with memory use / networking rather than availability
* managed modes cluster is still required for routing traffic
* edge / vpc modes cluster is not in data path
* enabled/disabled cluster components may need work / testing
* synchronous messaging model can cause reliability issues


## Block Storage Controller
Something along the lines of cinder from openstack as a common front-end could allow reuse of some management/monitoring between backends.

More common code may help make configuration / property lifecycle issues easier to resolve.


## Object Storage Gateway

* ufs / available backend
* improving handling of errors from backend, such as retries on connections, etc 
* persistence availability for S3 metadata
* database configuration cache / properties, reduce database use


## Console

* deploy in a VM behind ELB
    * could be more of a consideration for managed deployments etc
    * customer feedback is that service is less easy to manage in a service VM. Harder to configure and debug.

    
* multiple consoles would need centralized caching 
* long running tasks such as deleting a scaling group or creating an image from an instance or multi-delete for S3


## Cloud Controller

* single point of failure
* stateful backend services
    * resource reservations
    * background tasks
    * task polling
    * workflow

    
* database
    * management (postgres)
    * persistence for services

    
* service state coordination
* network information broadcast


# Proposals

## VPC Networking
Eucanetd could run on reduncant components such as ufs. Tomcat could be paired with eucanetd on each ufs host. We would need to coordinate work performed by eucanetd either by explicit control of the active host or by partitioning work between eucanetd hosts. This implies that ufs hosts would need to coordinate over the network view (no in-memory state)

Instance metadata is single point of failure (nginx, bridges), we could replace nginx with Java listeners (on ufs?)


## Edge Networking
We could restore support for redundant cluster controllers to avoid a single point of failure.

Switching to polling for network view would remove some failures on cluster outage.


## Approaches and Dependencies

* elasticache - for console shared cache
* move workflows to SWF
    * console
    * elb (in progress)
    * auto scaling
    * ec2

    
* SQS / queuing
    * service / console (periodic) task distribution
    * distributed events?
    * notification of events between components (or to console)
    * other service usage
    * ec2 import tasks

    

    
* alternative persistence such as Cassandra
    * might not be ideal for services such as SQS (at scale)
    * relation to midonet use of cassandra?

    
* Postgresql availability improvements
    * does not currently meet availability needs with base product or enhancements
    * may become simpler as less data is stored in postgres
    * postgres in a vm is another option to reduce size of main db

    
* vm services may be a way to make additional internal services more robust
* scalable support for cloudformation workflows (for example) 


## Related Areas and Concerns

* jgroups - hosts / discovery
    * multicast use (local rather than global from 4.3)
    * could replace with zookeeper, atomix, etcd (static config)
    * register hosts with one or two other "nodes"

    
* cloudwatch logs / logs into S3
    * reduces operations concerns when functionality is more distributed or in vms

    
* upgrades
    * complexity increases as we add persistence mechanisms
    * swf upgrades (versioning of workers / activities)

    
* configuration
    * distribution, particularly non Java components
    * transactional updates for consistency of multiple properties

    


# References

* [[5.0 Candidate Features|5.0-Candidate-Features]]





*****

[[tag:confluence]]
[[tag:rls-5.0]]
[[tag:illities]]
