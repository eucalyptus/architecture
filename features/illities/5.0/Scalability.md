* [Description](#description)
* [Tracking](#tracking)
* [Status](#status)
  * [Networking](#networking)
    * [VPC](#vpc)
    * [Edge](#edge)
    * [Broadcast](#broadcast)
* [Proposals](#proposals)
  * [Networking](#networking)
    * [VPC](#vpc)
  * [Related Areas and Concerns](#related-areas-and-concerns)
    * [Instance Launch Gating](#instance-launch-gating)
    * [Eucanetd Replacement](#eucanetd-replacement)
* [Priorities](#priorities)
  * [Investigations](#investigations)
  * [Network](#network)
* [References](#references)



# Description
Status, proposals and (5.0) priorities related to scalability.


# Tracking

* Status: Step #1, initial draft


# Status

## Networking

### VPC
Network BroadcastWith many instances, security groups, and other VPC resources the size of the network view can be large. This is particularly problematic for broadcasting of the network information.

Delays between network broadcasts can cause scale issues due to timeouts.

Instance LaunchWhen launching multiple instances creating the associated network resources can be a bottleneck.

Implementing midonet network resources for one instance is expected to take around one second not including the shared VPC resources.

Current understanding is that this is due to the number of resources rather than any specific resources, with dependencies dictating the necessary resource creation order.

Resource creation is currently single threaded for instance launch.

Eucanetd Midonet StatWhen there are many instances loading state from midonet on eucanetd restart is slow:


* 10K instances ~ 1 minute
* 100K instances ~10 minutes (estimated)
* etc

Eucanetd ErrorsThere is currently no mechanism for fault feedback from eucanetd to the cloud controller or for eucanet status, there is only a timeout for the network view being applied.


### Edge
Network view transforms to a "document" that can be "atomically" applied so scales well.


### Broadcast
The period broadcast of the network view can cause scalability issues when there are many instances due to the large size of the view.

The minimum time between broadcasts can be configured, but increasing the minimum time delays network resource modifications and causes user visible performance issues (such as slow instance launch)


# Proposals

## Networking

### VPC
Eucanetd MidonetWe could generate uuids for resource creation to eliminate possibility of duplicate resource creation and avoid the need for lookup based on unique / key properties.

We could perform additional actions concurrently for improved performance.

Midonet UsageWe could change our interaction with Midonet to be resource based. This would mean individual operations rather than applying a single view, e.g. create vpc, create instance networking, etc.

Using this resource focused interaction could improve scale by removing the need for bulk activities (though this could also be achieved in other ways such as persisting our model of midonets state)

Midonet APIChanges to the midonet API would be beneficial for our current architecture:


* export / dump data with fewer calls, less nesting / hierarchy for data

Instance MetadataThe scalability issue for instance metadata of many network resources could be resolved by mapping ids / uuids for each instance to reserved network.

0/8 network is sufficient for millions of instances. Instance to id mapping would be translated by midonet and the source address would identify the instance.

May need a load balancer to make metadata on ufs available (not a midonet lb which requires additional sw)

Network ViewThe network view could include version or changeset information for resources to simplify the work that eucanetd performs. In particular this could help with deletion of resources which must otherwise be determined by checking against midonet resources.

The network view could be ordered to better reflect dependencies, this would simplify midonet resource creation by eucanetd. Other model change could be to include node information for interfaces and to separate out the relationships from the properties of resources.

Network BroadcastDocument size could be an issue for network broadcasts. One simple way to reduce the broadcast size is to remove the base64 encoding of the view. For VPC mode the cluster and node controllers do not need much of the information contained in the view. For broadcast we could strip unnecessary information from the view to reduce the size.

Switching to polling of the view from node controllesr to ufs hosts would allow changesets / diffs to be queried by including additional context such as the current version of the view held by the node.

If we were to use polling and communication to ufs hosts then we may want to investigate using this for other purposes such as status information.

Another approach would be to avoid messaging for communication and use shared persistent storage for communication. In this case something like zookeepers watchers could be used to detect when network artifacts need to be implemented.


## Related Areas and Concerns

### Instance Launch Gating
Changes to the network broadcast / view could impact how we gate instance launch on the node controller.


### Eucanetd Replacement
We may replace the eucanetd midonet integration with a more integrated (i.e. Java) solution in a future release so should evaluate any eucanetd improvements with this goal in mind.


# Priorities

## Investigations

* Broadcast base64 encoding removal - reduce broadcast size by 1/4


## Network

* VPC metadata - currently requires many interfaces on cloud controller
* VPC eucanetd start up performance
* VPC eucanetd launching instances - concurrently create midonet network artifacts for instances
* VPC broadcast omit unneeded information - nodes do not require the full network view
* EDGE more efficient eucanetd per node (resource usage such as ipsets) 


# References

* [[5.0 Candidate Features|5.0-Candidate-Features]]



*****

[[tag:confluence]]
[[tag:rls-5.0]]
[[tag:illities]]
