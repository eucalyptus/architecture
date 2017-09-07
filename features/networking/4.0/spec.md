ARCH-18 / PRD-77

* [Overview](#overview)
  * [Background](#background)
* [Requirements](#requirements)
  * [Feature](#feature)
    * [General Requirements](#general-requirements)
    * [Security Requirements](#security-requirements)
* [Specification](#specification)
  * [Model / Components](#model-/-components)
  * [Service Interactions](#service-interactions)
    * [Configuration](#configuration)
    * [Network Metadata](#network-metadata)
    * [Eucanetd](#eucanetd)
  * [Feature Details](#feature-details)
    * [Eucanetd](#eucanetd)
    * [Metadata Changes](#metadata-changes)
    * [Services Tier Implementation Details](#services-tier-implementation-details)
  * [Client Tools](#client-tools)
  * [Administration](#administration)
  * [Upgrade](#upgrade)
  * [Security](#security)
* [Design Constraints / Considerations](#design-constraints-/-considerations)
  * [Phased Introduction](#phased-introduction)
* [Notes](#notes)
* [References](#references)



# Overview
Production-ready Edge networking


## Background
Remove cluster controller from data plane.


# Requirements

## Feature

### General Requirements

* Cluster controller should not route data to instances
* Each cluster should have distinct subnet




### Security Requirements

* AWS-compatible L2-isolation (and spoofing attacks prevention) between instances within and between security groups should be supported


# Specification

## Model / Components
Eucanetd service added for network configuration.


## Service Interactions

### Configuration
Network configuration will be stored in the database and distributed as necessary.


### Network Metadata
Network metadata will be distributed from the cloud controller to the cluster controller via a push utilizing the existing SOAP mechanism. The cluster controller will push metadata to the node controllers as required.


### Eucanetd
Node controllers will share network configuration and metadata with eucanetd via the filesystem.


## Feature Details

### Eucanetd
See references for tech preview information.


### Metadata Changes
User triggered metadata changes will result in a push of network data to the cluster controller(s). In edge mode we will not require separate actions (e.g. for IP address assign / unassign).

Initial outline of data that needs to make its way from CLC to eucanetd follows:




```
configuration (globally unique, cluster unique, edge unique, unknown/undecided):
  - (global) current CLC IP
  - (global) list of public IPs
  - (global) list of all cluster private VM subnets
  - (global) VM DNS domain name
  - (cluster) current CC IP
  - (cluster) private subnet (net, mask, GW, DNS)
  - (local) dhcpd location
  - (local) location, username of eucalyptus install
  - (local) VM bridge name
  - (local) log stuff
  - (unknown) VM MAC prefix
  - (unknown) list of all subnets to ignore NAT to el. IPs (if any) 
 
global instance information
  - name (unique, currently instance ID)
  - bridge name (maybe not needed)
  - MAC address
  - private IP
  - public IP
 
global security group information
  - name (unique, currently 'user-uuid')
  - group membership (private IPs)
  - rules (currently formatted almost exactly like input to euca-authorize)

```

### Services Tier Implementation Details
This section covers high level design details for the "services tier" (front end) of the feature.

Networking ServiceA networking service abstraction is introduced to encapsulate the behaviour of generic (legacy) and EDGE mode networking:

![](images/architecture/networking-services.png)

The dispatching networking service dispatches the currently enabled networking service which will either be the generic or EDGE implementation.

The networking service is responsible for the centralized aspects of network resource management:


* Reserving network resources
* Releasing unused network resources
* Processing changes in network resource ground truth

Instance Lifecycle HelpersInstance lifecycle helpers intercept points in the lifecycle of an instance in support of some aspect:

![](images/architecture/vm-instance-lifecycle-helpers.png)

Network Information BroadcasterThe network information broadcasts is responsible for periodic and event driven broadcast of network information to cluster controllers (ultimately to eucanetd via node controllers)

Addressing DispatcherThe addressing dispatcher abstraction is introduced to allow addressing state change messages to the cluster controller to be skipped in EDGE mode:

![](images/architecture/addressing-dispatcher.png)

The network information broadcaster registers an addressing interceptor to trigger a network information broadcast when address associations change.

Private Address ManagementThe PrivateAddress entity and associated PrivateAddressAllocator are introduced to support EDGE mode private addressing:

![](images/architecture/private-addresses.png)

For EDGE mode private network index is not used.


## Client Tools
Tool changes not required for this feature.


## Administration
A cloud property is added for EDGE networking configuration, the value is a JSON document.

Example configuration for edge networking via "cloud.network.network_configuration" cloud property:


```js
{
    "InstanceDnsDomain": "eucalyptus.internal",
    "InstanceDnsServers": [
        "10.111.5.28"
    ],
    "PublicIps": [
        "10.111.103.0-10.111.103.2",
        "10.111.103.6",
        "10.111.103.26-10.111.103.29"
    ],
    "Subnets":[
    ],
    "Clusters": [
        {
            "Name": "PARTI00",
            "MacPrefix": "d0:0d",
            "Subnet": {
                "Name": "10.111.0.0",
                "Subnet": "10.111.0.0",
                "Netmask": "255.255.0.0",
                "Gateway": "10.111.0.1"
            },
            "PrivateIps": [
                "10.111.103.30",
                "10.111.103.36",
                "10.111.103.38-10.111.103.43"
            ]
        }
    ]
}
```
The Name specified for a Subnet in the configuration is an arbitrary value, this can be used to define a subnet at the top level and reference it from a cluster:


```js
    "Subnets": [
        {
            "Subnet": "10.111.0.0",
            "Netmask": "255.255.0.0",
            "Gateway": "10.111.0.1"
        }
    ],
    "Clusters": [
        {
            "Name": "PARTI00",
            "MacPrefix": "d0:0d",
            "Subnet": {
                "Name": "10.111.0.0"
            },
            "PrivateIps": [
                "10.111.103.30",
                "10.111.103.36",
                "10.111.103.38-10.111.103.43"
            ]
        }
    ]  
```
as shown in the above example the "Name" for a subnet is optional and defaults to the value of the "Subnet" property.

When values are not provided in the configuration document default values are used as follows:


* Instance DNS domain : The value of the "cloud.vmstate.instance_subdomain" property appended to ".internal " with any leading "." removed
* Instance DNS servers : The value of the "system.dns.nameserveraddress" property interpreted as a comma separated list of addresses
* 
```
MAC Prefix : The value specified as a top-level property, falling back to the "cloud.vmstate.mac_prefix" cloud property
```

* Clusters : Cluster configuration is generated for each registered cluster when possible if not specified:
    * Name : The name of the partition
    * MAC Prefix : as above
    * Subnet : A single top-level subnet must be configured
    * Private IPs : The top level private IPs are used.

    


## Upgrade
Upgrade to EDGE not supported.


## Security

* Existing mechanisms will be used for distribution of network configuration and metadata. A node / eucanetd may have access to more (cluster specific) information than is strictly required.
* The eucanetd does not expose an API, it will read a file shared by a node controller that is secured using OS facilities.


# Design Constraints / Considerations

## Phased Introduction
Initially the implementation of edge mode will result in two distinct mechanisms for network configuration / metadata and distinct implementations of applying network configuration.

Ultimately existing network modes should be updated to use the new (SOAP) mechanisms for distribution of configuration and metadata and should use a shared library (or alternative) for applying network configuration.


# Notes

* Libvirt [firewall and network filtering](http://libvirt.org/firewall.html)may be useful in implementing L2-isolation. For example, the _clean-traffic_  filter "stops the most common bad things a guest might try, IP spoofing, arp spoofing and MAC spoofing."




# References

* [[3.4 Tech Preview EDGE Networking Doc|EDGE-Networking]]











*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:networking]]
