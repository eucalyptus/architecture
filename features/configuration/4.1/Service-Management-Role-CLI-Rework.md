
## Overview
This feature is about adding support for recent architectural changes to the admin tools in addition to improving the admin tools' interfaces.

  * [Overview](#overview)
    * [Goals](#goals)
    * [Non-goals](#non-goals)
  * [Tasks](#tasks)
    * [Client tools](#client-tools)
    * [Cloud controller](#cloud-controller)
  * [Questions](#questions)
  * [Issues](#issues)



### Goals

* Make the cloud setup and maintenance workflows more suitable for use with [[administrative roles|Personas-Specification]]
    * [EUCA-9926 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9926)
    * [EUCA-9927 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9927)
    * [EUCA-9928 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9928)
    * [TOOLS-359 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/TOOLS-359)

    
* Improve eucalyptus operators' ability to inspect the system's makeup and state
    * [EUCA-9536 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9536)
    * [EUCA-9537 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9537)
    * [EUCA-9538 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9538)

    
* Expose service groups to eucalyptus operators to improve their understanding and control of the system
* Give end users a way to obtain a list of service endpoints
    * [EUCA-9539 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9539)

    
* Address confusion and pain points surrounding the admin tools
    * [ JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/)
    * Unnecessarily large number of commands
    * Ease of confusion with euca2ools
    * euca-\* namespace

    
    * Awkward UIs
    * euca_conf
    * euca-modify-property

    

    
* Improve the UI for system property display and modification
* Add support for disabling user requests for all instances of a given service type

    
    * Using a property for this is unintuitive

    
* Add support for modifying the state of all instances of a given service type
* Add support for modifying the state of all members of a given service group


### Non-goals

* Fundamentally changing the way service management works
* Fundamentally changing the way credential management works


## Tasks
All new command and operation names are illustrative and not final. P1 indicates mandatory tasks, P2 indicates high-priority tasks that do not necessarily block the feature, and P3 refers to low-priority tasks.


### Client tools

*  **P1** : Replaceeuca-get-credentials with a wholly-client-side equivalent.
    * This decouples client configuration from the system's implementation.
    * This makes generating configurations for diverse clients simpler by enabling automation.
    * This requires a workingeuca-describe-endpoints command that works for regular users.

    
*  **P1** : Port the existing admin tools to the requestbuilder framework.
    * This enables use of STS credentials, and thus part of the administrative role workflow.
    * List of commands needed to maintain the current level of functionality:

    
    * euadmin-initialize-region
    * Initializes a new cloud

    
    * euadmin-get-admin-creds
    * Obtains super-admin credentials for use during setup

    
    * euadmin-describe-service-types
    * euadmin-register-service -t  _TYPE HOST_OR_URL_ 
    * euadmin-describe-services --by-host
    * euadmin-describe-services --by-type
    * euadmin-describe-services --by-endpoint
    * euadmin-deregister-service  _SERVICE_ 
    * euadmin-deregister-service  _GROUP_ 
    * euadmin-migrate-instances --source  _SERVICE_ 
    * euprop -a
    * euprop  _PROPERTY_  ...
    * euprop  _PROPERTY_ = _VALUE_  ...
    * This interface adds future-proofing for transactional property updates.

    
    * euprop  _PROPERTY_ =@ _FILE_  ...
    * This interface is needed to support commands like euadmin-configure-vmware

    
    * euprop --reset  _PROPERTY_  ...

    
    * This reduces confusion by reducing the number of command line utilities in the admin tool suite.
    * This reduces confusion by putting admin tool executables in different namespaces from euca2ools.
    * This eliminates awkward UIs from commands such aseuca_conf andeuca-modify-property.

    
*  **P1** : Implement euare-assumerole
    * [TOOLS-359 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/TOOLS-359)
    * This is a prerequisite for using administrative roles during system setup.

    
*  **P1** : Add [AWS signature version 4](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html) support to requestbuilder
    * [TOOLS-360 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/TOOLS-360)
    * This is a prerequisite foreuare-assumerole.

    
*  **P3** : Implement single-command role assumption (e.g.--as-role command line option)
*  **P3** : Implement automatic instance profile credential use.


### Cloud controller

*  **P1** : Cloud controllers shall provide a well-defined interface for a client tool with local access to obtain super-admin query credentials (not a zip file).
    * Query credentials are all that is necessary to obtain everything that the zip file contains.

    
*  **P1** : Ensure DescribeAvailableServiceTypes responses include service group types so it is possible for infrastructure administrators to know what to supply to euadmin-register-service when registering the user-facing service group.
*  **P1** : Make the functionality of DescribeServices accessible to all users, including anonymous users.
    * Not all users may have access to a CLC, which is currently the only source of correct service information.
    * This makes it possible to implement part of a client-side replacement foreuca-get-credentials.

    
*  **P1** : Ensurecloud-cert.pem is accessible to all users via a web service call.
*  **P2** : When DNS delegation is enabled, lists of services shall contain generic, DNS-based endpoints that refer to any active instance of each service. (e.g.compute.mycloud.example.com)

    
    * This is necessary for a client-side replacement foreuca-get-credentials to generate configuration files.

    
*  **P2** : Expose information about service groups and service group membership alongside service information via DescribeServices or a new operation, such as DescribeServiceGroupMembers.
    * This makes it possible for infrastructure administrators to clearly view which services' states should change in unison.
    * This makes it possible for infrastructure administrators to learn how to affect all members of a service group at once with operations such asDeregisterService andModifyService.

    
*  **P3** : Decompose RegisterService,DeregisterService,ModifyService, andDescribeServices into separate operations for services and service groups.
    * An example of such a decomposition is the following set of operations:


    * DescribeServiceTypes / DescribeServiceGroupTypes
    * RegisterServiceInstance /RegisterServiceGroup
    * DeregisterServiceInstance / DeregisterServiceGroup
    * ModifyServiceInstance / ModifyServiceGroup
    * DescribeServiceInstances /DescribeServiceGroups
    * AddServiceInstanceToGroup
    * RemoveServiceInstanceFromGroup
    * DescribeServiceGroupMembers
    * This composes the information available fromDescribeServiceInstances andDescribeGroups.

    

    
    * Most of the existing operations that this decomposition splits up are essentially "if-else" pairs that can be written in terms of two new methods.
    * This makes it possible to present services and service groups to infrastructure administrators separately.
    * If hiding the differences between services and service groups from end users is reasonable then client tools can do so.

    


## Questions

* Should super-admin credentials expire?


## Issues
[ JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/)





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:configuration]]
