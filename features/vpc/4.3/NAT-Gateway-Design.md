* [Description](#description)
* [Model / Persistence](#model-/-persistence)
  * [Entities](#entities)
  * [Persistence Facades / DAOs](#persistence-facades-/-daos)
* [Service](#service)
  * [Managers](#managers)
* [Backend](#backend)
  * [VPC Workflow](#vpc-workflow)
  * [Network Broadcast](#network-broadcast)
* [References](#references)



# Description
This document covers changes to the VPC service for support of NAT gateways.


# Model / Persistence

## Entities
A new  _NatGateway_ class is introduced for persistence of NAT gateway metadata. The entity has references to resources it uses:


* VPC
* Subnet
* Network interface

and also the identifiers for each resource. When the NAT gateway is deleted or failed the reference to other entities are cleared but the resource identifier fields are not.


## Persistence Facades / DAOs
A new _NatGateways / PersistenceNatGateways_  facade is added for working with NAT gateways.


# Service
This section covers functionality related to the user facing VPC service implementation.


## Managers
The  _VpcManager_  is updated with support for management of NAT gateways.

The  _ComputeService_  is updated with support for describing NAT gateways.


# Backend

## VPC Workflow
NAT gateways have state transitions that occur outside of API actions or polling of cluster resources. A new  _VpcWorkflow_ class is introduced to handle this work. Work performed here is a candidate for replacement by alternative workflow implementations such as Simple Workflow.

On creation of a NAT gateway the resource is in a "pending" state. The workflow is responsible for transitioning to "available" by:


* Creating the related network interface resource
* Associating the elastic IP

On deletion of a NAT gateway the resource is in a "deleting" state. The workflow is responsible for transitioning to "deleted" by:


* Disassociating the elastic IP
* Deleting the network interface

NAT gateway resources in a "failed" or "deleted" state remain visible via the API for an hour. The workflow is responsible for cleanup of expired NAT gateway metadata.


## Network Broadcast
The network broadcast is updated to include information for NAT gateways:


```xml
<vpc name="vpc-7377904f">
  <ownerId>000476990416</ownerId>
  <cidr>10.10.0.0/16</cidr>
  <dhcpOptionSet>dopt-f6703e05</dhcpOptionSet>
  <subnets>
    ...
  </subnets>
  <networkAcls>
    ...
  </networkAcls>
  <routeTables>
    <routeTable name="rtb-0d6760e5">
      <ownerId>000476990416</ownerId>
      <routes>
        <route>
          <destinationCidr>10.10.0.0/16</destinationCidr>
          <gatewayId>local</gatewayId>
        </route>
        <route>
          <destinationCidr>1.1.1.1/32</destinationCidr>
          <natGatewayId>nat-99528bb072b83cf9f</natGatewayId>
        </route>
      </routes>
    </routeTable>
    <routeTable name="rtb-380d260d">
      <ownerId>000476990416</ownerId>
      <routes>
        <route>
          <destinationCidr>10.10.0.0/16</destinationCidr>
          <gatewayId>local</gatewayId>
        </route>
      </routes>
    </routeTable>
  </routeTables>
  <natGateways>
    <natGateway name="nat-99528bb072b83cf9f">
      <ownerId>000476990416</ownerId>
      <macAddress>d0:0d:0f:bb:04:f4</macAddress>
      <publicIp>10.116.132.146</publicIp>
      <privateIp>10.10.10.8</privateIp>
      <vpc>vpc-7377904f</vpc>
      <subnet>subnet-3e787e00</subnet>
    </natGateway>
  </natGateways>
  <internetGateways>
    <value>igw-993ae7e7</value>
  </internetGateways>
</vpc>
```
The above example shows a NAT gateway and an associated route.


# References

* [EC2 VPC : NAT gateway management (JIRA)](https://eucalyptus.atlassian.net/browse/EUCA-11980)



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:vpc]]
