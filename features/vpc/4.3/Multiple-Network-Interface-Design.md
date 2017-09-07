
# Description
This document covers changes to the VPC service for support of multiple network interfaces.


# Analysis
This section describes investigation / analysis of multiple network interface behaviour.


## Attach/Detach for Pending Instance
AWS/EC2 forbids network interface attachment modifications for a pending instance.


## Resource Lifecycle
Network interface resources must be associated with the interface and not with an instance. Resources used by an eni may be released when an instance is terminated if the attachment specifies delete-on-terminate behaviour.


# Model / Persistence

## Entities
The  _NetworkInterface_ entity is updated to support querying for an attachment and to set the interface state based on attachment state (for hot/cold attach cases)

The  _PrivateAddress_ entity now references either an instance or a network interface for tracking resource ownership.

 _VmType_ is updated for persistence of the network interfaces limit for the type. 


# Service
This section covers functionality related to the user facing VPC service implementation.


## Managers
The  _VpcManager_  is updated with support for attach and detach of network interfaces.

 _VmTypesManager_ is updated to allow the network interfaces limit to be configured.




# Backend

## Instance State Polling
The polling of cluster controllers for instance state is updated to include processing of network interface attachments. This is used for attaching and detaching transitions.


## Network Broadcast
The network broadcast is updated to include the attachment identifier for network interfaces:


```xml
 <instances>
    <instance name="i-1b5c4503">
      <ownerId>000994694045</ownerId>
      <macAddress>d0:0d:a2:f1:51:a8</macAddress>
      <privateIp>172.31.2.226</privateIp>
      <vpc>vpc-3b1fdc87</vpc>
      <subnet>subnet-893ca466</subnet>
      <networkInterfaces>
        <networkInterface name="eni-a2f151a8">
          <ownerId>000994694045</ownerId>
          <deviceIndex>0</deviceIndex>
          <attachmentId>eni-attach-e98cf499</attachmentId>
          <macAddress>d0:0d:a2:f1:51:a8</macAddress>
          <privateIp>172.31.2.226</privateIp>
          <sourceDestCheck>true</sourceDestCheck>
          <vpc>vpc-3b1fdc87</vpc>
          <subnet>subnet-893ca466</subnet>
          <securityGroups>
            <value>sg-6300851f</value>
          </securityGroups>
        </networkInterface>
      </networkInterfaces>
      <securityGroups>
        <value>sg-6300851f</value>
      </securityGroups>
    </instance>
```

## Network Interface Route States
The network broadcast processing also fires events ( _VpcRouteStateInvalidationEvent_  ) for any invalid route states that are detected.  _VpcWorkflow_ has a task to process any routes that may have incorrect states and update them.


## Instance Metadata
The metadata returned for a VPC instance is updated to include information for all attached network interfaces.


# References

* [EC2 VPC : Network interface attaching/detaching state support (JIRA)](https://eucalyptus.atlassian.net/browse/EUCA-12000)



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:vpc]]
