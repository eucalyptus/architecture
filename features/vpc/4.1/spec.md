* [Description](#description)
* [Tracking](#tracking)
* [Analysis](#analysis)
  * [Security Group Egress Rules](#security-group-egress-rules)
  * [Security Group Associations](#security-group-associations)
  * [Resource Tagging/Filtering](#resource-tagging/filtering)
  * [MAC Address Handling](#mac-address-handling)
  * [Impact on EC2 Dependents](#impact-on-ec2-dependents)
* [Use Cases](#use-cases)
  * [EC2 Platform Configuration](#ec2-platform-configuration)
  * [Default VPC](#default-vpc)
  * [Single Public Subnet VPC](#single-public-subnet-vpc)
  * [Public/Private Subnets VPC](#public/private-subnets-vpc)
  * [Multiple Availability Zone VPC](#multiple-availability-zone-vpc)
  * [Elastic IP for VPC Instance](#elastic-ip-for-vpc-instance)
  * [Secured Network VPC](#secured-network-vpc)
  * [Restore Default VPC](#restore-default-vpc)
  * [Associate Private IP with EBS Instance (PRD-51)](#associate-private-ip-with-ebs-instance-(prd-51))
  * [Multiple Network Interfaces for Instance (PRD-53)](#multiple-network-interfaces-for-instance-(prd-53))
* [Elements](#elements)
  * [VPC Manager](#vpc-manager)
  * [VPC Broadcaster](#vpc-broadcaster)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
  * [Network Domain](#network-domain)
  * [Virtual Private Cloud (VPC)](#virtual-private-cloud-(vpc))
  * [DHCP Options](#dhcp-options)
  * [Subnet](#subnet)
  * [Route Table](#route-table)
  * [Internet Gateway](#internet-gateway)
  * [Network Interface](#network-interface)
  * [Elastic IP](#elastic-ip)
  * [Security Group](#security-group)
* [Milestones](#milestones)
  * [Sprint 1](#sprint-1)
* [References](#references)



# Description
As a cloud user, I would like to see Eucalyptus present network semantics similar to that of AWS VPC, but only to the extent that makes sense for a private cloud.


# Tracking

* PRD-212 (PRD-51, PRD-53, PRD-234)
* ARCH-65
* Status: Step #1, initial draft


# Analysis
This section is background material, inclusion in this section does not imply any action is being taken.


## Security Group Egress Rules
VPC security groups support egress rules in addition to the ingress rules we currently support.


## Security Group Associations
The security group membership for instances can be changed with VPC security groups unlike the classic security groups we currently support.


## Resource Tagging/Filtering
Existing elements (e.g. instances) would require updating for VPC related filters. New abstractions would require tagging/filtering support.


## MAC Address Handling
We currently generate MAC addresses for instances based on the instance identifier, this may no longer be feasible as MAC addresses are required for network interfaces in VPC.


## Impact on EC2 Dependents
Services using EC2 functionality will need to be updated:


* Auto Scaling
* CloudFormation
* EC2 - Imaging VM resources
* Elastic Load Balancing - User facing functionality and ELB VM resources




# Use Cases
Non-exhaustive use cases for VPC service tier.


## EC2 Platform Configuration
An infrastructure or resource administrator configures the platform (EC2-Classic|VPC) for a cloud and/or account (T.B.D.)


## Default VPC
A cloud users account has EC2-VPC platform (DescribeAccountAttributes action) and the accounts default VPC is used for all networking. The supported Default VPC functionality may be a subset of the AWS/EC2 functionality but should cover at least one basic AWS/EC2 VPC usage scenario.


## Single Public Subnet VPC
A cloud user runs an instance in a VPC with a single public subnet, an EC2 managed network interface, and an internet gateway/route table enabling communication to the instance via its (requested on launch) public IP.


## Public/Private Subnets VPC
A cloud user runs two instances in a VPC, one in a public subnet and one in a private subnet.


## Multiple Availability Zone VPC
A cloud user runs an instance in a VPC with multiple subnets using multiple availability zones.


## Elastic IP for VPC Instance
A cloud user runs and instance in a VPC and associates a (VPC) elastic IP address.


## Secured Network VPC
A cloud user runs an instance in a VPC with a single public subnet, and an internet gateway to enable communication to the instance. Network ACLs are defined to secure access to the subnet.


## Restore Default VPC
A cloud user deletes \[part of] their default VPC, a resource administrator restores it.


## Associate Private IP with EBS Instance (PRD-51)
A cloud user associates a private IP with an ebs instance for great good. The private IP belongs to a VPC subnet and is either associated with an instance via a (VPC) network interface using the AssociateAddress action or is specified when using the RunInstances action.


## Multiple Network Interfaces for Instance (PRD-53)
A cloud user attaches multiple (VPC) network interfaces to an EC2 (VPC) instance that supports it (EC2 instance type). The network interfaces my be attached to an instance using the AttachNetworkInterface action and/or be specified when using the RunInstances action.


# Elements

## VPC Manager
The VPC manager exposes EC2 VPC actions to cloud users.


## VPC Broadcaster
The VPC broadcaster sends the network information to the CC (or elsewhere) to be implemented.

![](images/architecture/vpc.png)


# Interactions
EC2 User -> VPC Manager : Configures VPC via EC2 actions

VPC Broadcaster -> Cluster Controller : Applies VPC configuration


# Abstractions

## Network Domain
Enumeration representing the EC2 classic and VPC domains.


## Virtual Private Cloud (VPC)
Represents an EC2 VPC, a region specific logically isolated virtual network in which to run instances.


## DHCP Options
DHCP configuration for an EC2 VPC .


## Subnet
An EC2 VPC subnet, an availability zone and VPC specific network subnet.


## Route Table
An EC2 VPC route table.


## Internet Gateway
An EC2 VPC internet gateway.


## Network Interface
An EC2 VPC network interface for use with a VPC instance. Can be associated with one or more public (elastic) and private IP addresses.


## Elastic IP
Represents an EC2 classic (region specific) or VPC domain specific elastic IP address (VPC addresses are not for a particular VPC)


## Security Group
Represents an EC2 classic (region specific) or VPC specific security group.


# Milestones

## Sprint 1
The sprint 1 goal is to support the "Single Public Subnet VPC" use case.


# References

* [Amazon Virtual Private Cloud (docs.aws.amazon.com)](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html)
* [Differences Between EC2-Classic and EC2-VPC (includes default VPC; docs.aws.amazon.com)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-vpc.html)
* [Default VPC (docs.aws.amazon.com)](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/default-vpc.html)
* [Private IP Addresses Per ENI Per Instance Type (docs.aws.amazon.com)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI)
* [Resource tagging for EC2, including VPC (docs.aws.amazon.com)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions)





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:vpc]]
