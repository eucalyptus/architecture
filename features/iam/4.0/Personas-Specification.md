ARCH-13 / PRD-54

* [Overview](#overview)
  * [Background](#background)
  * [Dependencies](#dependencies)
* [Requirements](#requirements)
  * [Feature](#feature)
    * [General Requirements](#general-requirements)
    * [New User Model](#new-user-model)
    * [Security Requirements](#security-requirements)
    * [UX Requirements](#ux-requirements)
* [Specification](#specification)
  * [Model / Components](#model-/-components)
  * [Service Interactions](#service-interactions)
  * [Feature Details](#feature-details)
    * [Privileged Personas](#privileged-personas)
    * [Privileged Users and Roles](#privileged-users-and-roles)
    * [LDAP Integration](#ldap-integration)
  * [Client Tools](#client-tools)
  * [Administration](#administration)
  * [Upgrade](#upgrade)
  * [Security](#security)
  * [Documentation](#documentation)
* [Design Constraints / Considerations](#design-constraints-/-considerations)
  * [Phased Introduction](#phased-introduction)
* [Testing / QA](#testing-/-qa)
* [Notes](#notes)
* [References](#references)



# Overview
Delineate the various roles of infrastructure administration, resource administration, IAM account administration, so that an admin is clear about his/her role, and the operations he/she can perform via that role.



This specification includes management functionality and auditing of privileged operations.


## Background
IAM roles define similar functionality and this should be extended to meet administrative requirements in Eucalyptus.


## Dependencies

*  IAM roles / policies.


# Requirements

## Feature

### General Requirements

* privileged functionality should only be exposed via roles or local access
* a user can assume more than one role (is there a limit?)
* provide canned policies for privileged roles
* policy language should allow for specifying eucalyptus-specific operations that are needed for implementing IA
* audit trail for privileged operations and change of privileges


### New User Model

* Eucalyptus should clearly differentiate between different privileged cloud personas (currently all accommodated by the ''eucalyptus'' account) and provide ways to compartmentalize their privileges
* Eucalyptus should be able to accommodate simple deployments where most of the below roles are played by 1 or 2 individuals
* Eucalyptus should provide the ability to define which roles are needed for a particular deployment AND what each of these roles are going to be able to do

The eucalyptus account is currently used to perform a variety of privileged operations ranging from cloud setup to cross-account resource management. In the new user model, there is going to a single super privileged user that can do all functionality currently available to the ''eucalyptus'' account but be limited by local-host access only. This user can be used to perform privileged operations when needed using local-host access and can bootstrap other privileged accounts/users/roles that can be used remotely and delegate a customizable set of privileges (defined by policies) to them.


### Security Requirements

* only CSA can
    * define privileged policies
    * define privileged policies to users and roles
    * grant/revoke access to privileged roles

    
* by default, grant policies for privileged roles should deny access by anyone
* accounts with privileged access should not have default (preset) credentials
* it should be possible to limit some functionality to CSA only (but it should be possible to delegate it to another privileged persona if needed)
* it should be possible to limit access to super privileged functionality (eg., modification of privileged roles/policies and euca-modify-property script executing functionality) by an additional protection mechanism(local root only?)


### UX Requirements

* That usage of privileged personae should not require extra steps from the GUI console once the policies have been defined and the user is logged in (usage of privileged personae should be transparent to the user).
* That usage of privileged personae should not require extra steps from the CLI tools once the policies have been defined (assumption of roles from CLI may require extra step you mentioned above)
* That options which are not allowed for a logged in user of a GUI console are either hidden or disabled (which of these to use will be TBD on a case-by-case basis)
* That options which are not allowed for a user of CLI tools will have a clear error message indicating cause and remedy
* That canned policies are provided with Eucalyptus
* That predefined roles using the canned policies will be provided
* These predefined policies and roles must be editable by those with permissions to do so
* That cloud admins or users with IAM permissions can easily assign full roles or just the operations they want to grant access to with any level of desired granularity
* That any errors related to privileged personae must have clear and concise error messages returned indicating cause and remedy to be displayed in either CLI or GUI


# Specification

## Model / Components
IAMExisting roles functionality is updated to allow a single role to have cross-account access. Roles created in the eucalyptus administrative account can apply across-accounts.

The concept of a system user (in addition to system administrator) is introduced. The system user may have administrative privileges but a policy check is required to determine actual permissions.

Policy evaluation is updated to allow for the eucalyptus account to be referenced via alias rather than by account number. This allows for standard default policies even though the account number for the "eucalyptus" account varies between deployments.

Extension actions for EC2 and IAM are now permitted in policy, these actions cover account management (IAM) and instance type management (EC2)

Internal service authorizationInternal services are updated to support policies, the following eucalyptus specific vendors are added:


* eureport - reporting service
* euprop - properties service
* euserv - empyrean service
* euconfig - configuration service

Theses services can now be invoked by the CSA or any administrative role with a policy that permits the actions. Actions that were previously available to any user may now require permission in policy (e.g. DescribeServices)


## Service Interactions
Existing model for permissions check is used by services, extended to administrative operations and existing cloud administrator check is updated or removed.


## Feature Details

### Privileged Personas

* the ''Cloud Super Admin'' (CSA)
    * the super powerful user, which can perform any privileged operation in Eucalyptus and delegate these privileges
    * should have limited access (local root only?)
    * the only user who can create, modify and delete privileged policies and assign these policies to users

    
* the "Cloud Account Admin" (CAA)
    * can manage accounts

    
* the ''Cloud Resource Admin'' (CRA)
    * can manage AWS-defined resources (such as S3 objects, instances, users, etc) across accounts
    * from PRD-37, typical responsibilities
    * Management (cloud resources, policies, quotas, users, groups)
    * Monitoring (capacity, usage)
    * Reporting (usage reporting, account activity, audit trail)
    * Backup and Restore

    

    
* \* the ''Infrastructure Admin'' (IA)
    * can perform operations related to system setup and management
    * from PRD-37, typical responsibilities
    * installation and configuration
    * prepare environment
    * install Eucalyptus
    * configure Eucalyptus

    
    * Monitoring and Maintenance
    * Infrastructure supporting the cloud
    * Cloud management layer
    * Upgrades, security patches
    * Diagnostics and troubleshooting

    

    
    * Backup and Restore

    

    


### Privileged Users and Roles
Policies for roles created in the eucalyptus account will apply across accounts unless otherwise specified in the policy.


* Accounts
    * Cloud super admin

    
* Roles
    * Cloud Account Admin
    * manages accounts
    * policy permits - All IAM actions for all resources outside of the "eucalyptus" account

    
    * Cloud Resource Admin
    * manages resources other than IAM for existing accounts
    * policy permits - All autoscaling, cloudwatch, ec2 (except ModifyInstanceType), elasticloadbalancing, s3, and reporting actions. IAM read actions forresources outside of the "eucalyptus" account.

    
    * Infrastructure Admin

    
    * configures and manages a eucalyptus deployment
    * policy permits - All configuration, properties and services actions

    

    

Administrative roles will have well known ARNs:


```
 arn:aws:iam::eucalyptus:role/eucalyptus/AccountAdministrator

 arn:aws:iam::eucalyptus:role/eucalyptus/InfrastructureAdministrator

 arn:aws:iam::eucalyptus:role/eucalyptus/ResourceAdministrator
```
The alias "eucalyptus" is used in place of an account number to simplify assuming an administrative role. The path "/eucalyptus" is used to identify these roles as default administrative roles. There will be one default policy associated with each administrative role, with the policy named the same as the role it is associated with.

Administrative roles will be created on cloud start if a role with the expected name is not found. The CSA can modify the default roles and the associated policies and no way to reset the roles/permissions is provided.

To use an administrative role the assume role policy for the role is updated to permit a user to assume that role, if the user is not an account administrator then the users policy must also permit the role to be assumed.


### LDAP Integration
No specific integration with LDAP is provided but accounts under LDAP control can be configured as administrative accounts by allowing those account to assume the personas roles.






## Client Tools
Euca2ools will be updated with general IAM roles support and to support assuming resource administator role.



Administrative tools will be updated to support assuming personas (specific roles)


## Administration
Persona role administration is performed by cloud administrator.



Audit trail for privileged operations is a log file that could be modified by user with system access. Review of audit trail requires system access.


## Upgrade
On cloud start after an upgrade the personas roles will be created.


## Security



## Documentation



# Design Constraints / Considerations

## Phased Introduction
Support for the full roles specification will be introduced in phases which are:


1. Role names are hard coded -- they cannot be altered either on the server or CLI. This means that each implementation on the client side of a privileged operation will know ''apriori'' the name of the role to assume.
1. Role names can be specified as configuration to CLI tools and UI server -- a user will be able to change the Role used on a ''per operation basis''. This means that if a different role should be used for a certain operation, based on server side changes, then there is a ''mechanism'' for configuring the client to use that alternative Role.
1. Role names will be determined dynamically by tool from server -- there will be a ''protocol'' between the client and the server to determine what Roles grant access to which operations.


# Testing / QA



# Notes

* euca-modify-property should be separated into 2 operation: to modify properties (for IA) and to modify runtime (by default, for CSA only)
* UI: how to distinguish between expired and invalid credentials?! (if valid, but expired, the error message can say that they are expired)
* lifetime of STS credentials for privileged roles
    * should be short, allow for one operation only?

    
* \* role discovery by client tools and UI
    * should only work for the privileged roles, but not any roles that an account is allowed to assume

    
* some operations typically performed by IA, also need to be available to other users and account admins should be able to delegate these privileges
* 
    * DescribeServices
    * any others?

    


# References

* [https://github.com/eucalyptus/architecture/wiki/iam-3.3-roles-spec](https://github.com/eucalyptus/architecture/wiki/iam-3.3-roles-spec)
* [https://github.com/eucalyptus/architecture/wiki/iam-3.3-roles-design](https://github.com/eucalyptus/architecture/wiki/iam-3.3-roles-design)





*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:iam]]
