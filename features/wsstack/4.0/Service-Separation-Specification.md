ARCH-19 / PRD-76

* [Overview](#overview)
  * [Background](#background)
  * [Dependencies](#dependencies)
* [Requirements](#requirements)
  * [Feature](#feature)
    * [General Requirements](#general-requirements)
* [Specification](#specification)
  * [Model / Components](#model-/-components)
  * [Service Interactions](#service-interactions)
  * [Feature Details](#feature-details)
    * [Message Binding](#message-binding)
    * [Service Pipelines](#service-pipelines)
    * [Dispatching Service Implementation](#dispatching-service-implementation)
    * [Service Specific Functionality](#service-specific-functionality)
  * [Client Tools](#client-tools)
  * [Administration](#administration)
    * [Updates For euca_conf](#updates-for-euca_conf)
    * [Registration Commands](#registration-commands)
  * [Upgrade](#upgrade)
  * [Security](#security)
  * [Documentation](#documentation)



# Overview
I want to be able to separate the different user-facing Services from the host that hosts the database, so that I can enable / disable and deploy each service individually on a separate host in a scalable (active / active) and secure manner.


## Background



## Dependencies
Depends on object storage gateway (OSG) work on active/active service support.


# Requirements

## Feature

### General Requirements

* Deployment of user facing service in active / active configuration on hosts separate from the database
* Registration of all user facing services in one command
* Ability to change component IP address post configuration

AnalysisService Review

Object storage gateway (OSG) changes for 4.0 add support for active/active services. The remaining user facing services will build on that support:


* Auto Scaling
* CloudWatch
* EC2 (Compute)
* ELB (LoadBalancing)

    
* IAM (Euare)

    
* STS (Tokens)

The 4.0 CloudFormation tech preview will also support active/active deployment.

Active/active services must not have in memory state, the following services are therefore suitable for direct conversion to active/active:


* IAM (Euare)
* STS (Tokens)

The following services will require a stateful backend component:


* Auto Scaling
* CloudWatch
* EC2 (Compute)
* ELB (LoadBalancing)

    

Placement of these services is not a requirement, so they need not be registerable.

Deployment ConstraintsThere is no requirement for optional services, it is expected that at least one of each supported user facing service is registered.

Service AffinityThere is no requirement for affinity between user facing services on a host. For example, if the OSG accesses IAM then it may communicate with another user facing service host rather than using a local IAM service. If this becomes performance impacting then we should revisit.

Service PathsUser facing services are resolved using a URL path when the request host (HTTP header) does not identify the target service. We should ensure that the service paths used in previous releases are supported for separated services.



Open Issues
* Use of separated services from instances requires that services are available on the database host(s)
* Administration commands use the environment variable EC2_URL to determine services endpoints. This is incorrect when the EC2 service is separated out.


# Specification

## Model / Components
Stateful backend modules are created for Auto Scaling, CloudWatch, EC2 and ELB:


* autoscaling-backend
* cloudwatch-backend
* loadbalancing-backend

For EC2 the existing "cluster-manager" module is used though this may later be broken out into a "compute-backend".

User facing service modules are created for Auto Scaling, CloudWatch, EC2 and ELB:


* autoscaling-service
* cloudwatch-service
* compute-service
* loadbalancing-service

These modules are stateless and support registration in an active/active configuration.


## Service Interactions
There are no new service interactions for this feature, but existing interactions will change to use the user facing service components rather than backend components.

The backend components are logically a part of each service and should not be accessed from other services.


## Feature Details

### Message Binding
Message bindings are moved to service modules, backend component messages use only the internal (generated) bindings.


### Service Pipelines
Pipelines and web service framework classes are move to the new service modules. Public backend pipelines are removed leaving only the internal pipeline(s).


### Dispatching Service Implementation
Each of the services with a stateful backend component has a user facing service component that is responsible for receiving and dispatching messages from clients.

IAM AuthorizationIAM authorization is performed in the service tier. The authorization check verifies that the user MAY be permitted to invoke the action but does not evaluate resources or conditions so some messages will be rejected by backend checks.

IAM Context PropagationIAM condition keys now support declaration of evaluation constraints. The only supported constraint initially is "ReceivingHost" which ensures the key is evaluated on the host that receives the message to allow for conditions that require that context for evaluation. This is used for the "aws:SourceIp" condition key and will also apply to the "aws:SecureTransport" condition key when implemented.

Propagation of the context is achieved as follows:


```java
AsyncRequests.sendSyncWithCurrentIdentity( Topology.lookup( AutoScalingBackend.class ), request )
```
This will cause evaluation of IAM condition keys and inclusion of this context and the callers identity in the outbound message.

Message HierarchiesService messages must be distinct, this includes the messages for a single service that are handled by the user facing service and backend. There are distinct message hierarchies for each service in the common module which must have the same structure. Backend messages are created by using the new BaseMessages utility method:


```java
BaseMessages.deepCopy( backendResponse, request.getReply( ).getClass( ) )
```
This will create a copy of the given message using the given message type (which must have the same structure)

Error PropagationErrors from backend components must be propagated to clients when appropriate. Each user facing service handles errors from backend services and throws it's own errors with the approriate code / HTTP status. When the user facing service and backend component are on separate hosts the error information is propagated via the SOAP fault.


### Service Specific Functionality
Auto Scaling Service Message ValidationMessage validation for Auto Scaling is performed in the service tier. The validation performed requires only the request message and is configured via the Mule settings.

Load Balancing Client IdentificationThe load balancing service performs checks on the source of messages to authorize requests from servo VMs. The user facing service for load balancing adds the source IP address information to the message to allow this backend authorization.


## Client Tools
Client tools (e.g. Euca2ools) operate as before, it is not expected that any configuration changes are required.

The path for the compute service (EC2) is updated but the old path (/services/Eucalyptus) is still supported.


## Administration
Administration tools are updated to support registration of user facing services.


### Updates For euca_conf
The new euca_conf options are:


```text
  --register-service    Add a new service in EUCALYPTUS.
  --deregister-service  Remove an existing service from EUCALYPTUS. See also
                        --list-services.
  -T <service type>, --service-type=<service type>
                        Type of the service.
                        Used with --register-service & --deregister-service.
...
  -N <service name>, --service-name=<service name>
                        Name of service.
                        Used with --register-service & --deregister-service.
  --list-services       List current status of Eucalyptus services.
...
```
These options allow registration and de-registration of each user facing service individually and as a group via the "user-api" service type which allows registration of all user facing services on a host:


```text
# euca_conf --register-service --host IP --service-type=user-api [--no-sync] NAME
```
By default this command will synchronize keys, but as with other registration commands the "no-sync" option can be specified to disable key synchronization.


### Registration Commands
For registration of all user facing services without key synchronization the following command can be used:


```text
# euca-register-service --help
Usage: euca-register-service [options] name
    name - service's name (must be unique)
Options:
  -h, --help            show this help message and exit
  -T TYPE, --type=TYPE  The type of the service to register.
  -P PARTITION, --partition=PARTITION
                        The partition where the service should be registered.
  -H HOST, --host=HOST  The IP address of the host on which to register the
                        service
  -p PORT, --port=PORT  new component's port number (default: 8773)
  Standard Options:
    -D, --debug         Turn on all debugging output
    --debugger          Enable interactive debugger on error
    -U URL, --url=URL   Override service URL with value provided
    --region=REGION     Name of the region to connect to
    -I ACCESS_KEY_ID, --access-key-id=ACCESS_KEY_ID
                        Override access key value
    -S SECRET_KEY, --secret-key=SECRET_KEY
                        Override secret key value
    --version           Display version string
```
The available service types can be listed using:


```text
# euca-describe-service-types 
SERVICE    cluster                  register,partitioned,modifiable    The Cluster Controller service
SERVICE    storage                  register,partitioned,modifiable    The Storage Controller service
SERVICE    autoscaling              register,modifiable,internal    Auto Scaling API service
SERVICE    tokens                   register,modifiable,internal    STS API service
SERVICE    euare                    register,modifiable,internal    IAM API service
SERVICE    cloudformation           register,modifiable,internal    Cloudformation API service
SERVICE    user-api                 register,modifiable,internal    The service group of all user-facing API endpoint services
SERVICE    vmwarebroker             register,partitioned,modifiable    The VMware Broker service
SERVICE    objectstorage            register,modifiable,internal    S3 API service
SERVICE    compute                  register,modifiable,internal    the Eucalyptus EC2 API service
SERVICE    loadbalancing            register,modifiable,internal    ELB API service
SERVICE    arbitrator               register,partitioned,modifiable    The Arbitrator service
SERVICE    cloudwatch               register,modifiable,internal    CloudWatch API service
SERVICE    eucalyptus               register,modifiable,internal    eucalyptus service implementation
SERVICE    walrusbackend            register,modifiable,internal    The legacy Walrus Backend service
SERVICEGROUP    user-api                 autoscaling,tokens,compute,objectstorage,loadbalancing,cloudwatch,euare
GROUPMEMBER    autoscaling              user-api
GROUPMEMBER    tokens                   user-api
GROUPMEMBER    euare                    user-api
GROUPMEMBER    objectstorage            user-api
GROUPMEMBER    compute                  user-api
GROUPMEMBER    loadbalancing            user-api
GROUPMEMBER    cloudwatch               user-api
```

## Upgrade
On upgrade to 4.0 user facing services must be registered.


## Security
A deployment with user facing services on a separate host allows for better isolation of database hosts.


## Documentation
New service registration administration commands should be documented.





*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:wsstack]]
