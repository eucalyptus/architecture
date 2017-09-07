* [Description](#description)
* [Tracking](#tracking)
  * [Related Items](#related-items)
* [Analysis](#analysis)
  * [Component Placement](#component-placement)
  * [Edge Mode Network Requirements](#edge-mode-network-requirements)
  * [Backend Messaging](#backend-messaging)
  * [Network Configuration](#network-configuration)
  * [Packaging](#packaging)
  * [Upgrade](#upgrade)
* [Use Cases](#use-cases)
  * [Managed Mode Upgrade](#managed-mode-upgrade)
* [Implementation](#implementation)
  * [Packaging / Install](#packaging-/-install)
  * [Cloud Controller](#cloud-controller)
    * [Network Mode](#network-mode)
    * [Properties](#properties)
    * [Upgrade](#upgrade)
    * [Invalid Configuration](#invalid-configuration)
  * [Eucalyptus config](#eucalyptus-config)
  * [Cluster Controller](#cluster-controller)
  * [Node Controller](#node-controller)
  * [eucanetd](#eucanetd)
* [Risks](#risks)
* [References](#references)



# Description
This document covers removal of managed modes in the 4.4 release.


# Tracking

## Related Items

* [EUCA-11830](https://eucalyptus.atlassian.net/browse/EUCA-11830) PROPERTY MGMT - CLOUD.NETWORK properties cleanup


# Analysis

## Component Placement
Managed modes locate eucanetd on the cluster controller. With the removal of managed modes this will no longer be a supported deployment.


## Edge Mode Network Requirements
As the remaining classic networking mode edge is the obvious choice for replacement of managed mode in like for like deployments.

Edge mode has an additional network requirement for a public IP address assigned to each node.


## Backend Messaging
For backwards compatibility we may want to preserve message elements related to removed functionality.


## Network Configuration
We do not want to make existing cloud configuration invalid (on upgrade), so must accept configuration for managed modes when setting the  _cloud.network.network_configuration_  property.


## Packaging
The VTUN eucanetd dependency will no longer be required.


## Upgrade
Although upgrade of a managed mode cloud to 4.4 is not supported we should handle configuration created in previous version and ensure that if you were to upgrade the database schema is correctly updated.

This would mean that an unsupported upgrade path could be:


* terminate all instances
* stop all cloud components
* upgrade / install / remove components (i.e. move eucanetd install to node controllers from cluster controllers)
* update configuration files
* start all cloud components
* update network configuration on cloud controller


# Use Cases

## Managed Mode Upgrade
A managed mode cloud is upgraded to 4.4.


* Logs and faults reflect the use of a network mode that is no longer supported.


# Implementation

## Packaging / Install
The eucalyptus.conf configuration file should be updated to remove references to managed modes (or state they are removed?)


## Cloud Controller

### Network Mode
The  _ManagedNetworkingService_  implementation should be removed. Any managed mode specific _VmInstanceLifecycleHelpers_  such as  _PrivateNetworkIndexVmInstanceLifecycleHelper_  should be removed along with associated resource classes such as  _PrivateNetworkIndexResource_ .

The network information broadcast should be updated to remove any managed mode specific elements/content.

Management of extant networks can be removed from  _NetworkGroups_ along with the associated entities ( _ExtantNetwork_ ,PrivateNetworkIndex ). References from  _NetworkGroup_ to extant network should be removed.  _VmInstance_  must be updated to remove references to  _PrivateNetworkIndex._ 

 _ClusterConfiguration_ should be updated to remove vlan/index, vlan flag, and addresses per network settings.


### Properties
We should remove the following configuration properties:


* cloud.network.global_max_network_index
* cloud.network.global_max_network_tag
* cloud.network.global_min_network_index
* cloud.network.global_min_network_tag
* cloud.network.network_tag_pending_timeout

The network index timeout is also used for private addresses:

 _cloud.network.network_index_pending_timeout_ 

we could rename this property.


### Upgrade
Database tables related to managed mode resource tracking should be removed;


* metadata_extant_network
* metadata_network_indices

columns that are no longer required should be removed:


* config_component_base#cluster_use_network_tags
* config_component_base#cluster_min_network_tag
* config_component_base#cluster_max_network_tag
* config_component_base#cluster_min_addr
* config_component_base#cluster_min_vlan// max network index ...
* config_component_base#cluster_addrs_per_net
* metadata_instances#metadata_vm_network_index


### Invalid Configuration
Configuration that uses a managed mode is ignored and a fault is triggered and an error logged:


```text
************************************************************************
  ERR-1017 2016-09-12 21:21:46 Invalid network configuration. Networking for instances not operational.

   condition: Unable to apply network configuration
       cause: Managed networking modes are no longer supported
   initiator: Eucalyptus
    location: Eucalyptus
  resolution: 
          Use a supported networking mode [ EDGE | VPCMIDO ]
      
************************************************************************
```
The cloud administrator is expected to make changes to the cloud deployment and configuration to address the issue.


## Eucalyptus config
Clean config from MANAGED and MANAGED-NOVLAN and remove mode deprecation statement. [EUCA-12760](https://eucalyptus.atlassian.net/browse/EUCA-12760)


## Cluster Controller
Clean up code from special handling for managed networking. [EUCA-12761](https://eucalyptus.atlassian.net/browse/EUCA-12761)

Remove VNET_SUBNET, VNET_NETMASK, and VNET_ADDRSPERNET properties from code and documentation.


## Node Controller
Remove managed mode specific instance gating and configuration checking. [EUCA-12762](https://eucalyptus.atlassian.net/browse/EUCA-12762)


## eucanetd
Removal of MANAGED and MANAGED-NOVLAN modes from eucanetd entails:


* Clean up GNI parsing/validation (EUCA-12710): MANAGED- and MANAGED-NOVLAN-specific parameters include:
    * managedSubnet
    * minVlan
    * maxVlan
    * segmentSize

    
* Remove MANAGED and MANAGED-NOVLAN drivers (EUCA-12711)
* Clean up VTUN dependency (installation, configuration, docs, ITAR export)


# Risks

* Regressions in other network modes


# References

* [Epic for managed mode removal (EUCA-12677)](https://eucalyptus.atlassian.net/browse/EUCA-12677)





*****

[[tag:confluence]]
[[tag:rls-4.4]]
[[tag:networking]]
