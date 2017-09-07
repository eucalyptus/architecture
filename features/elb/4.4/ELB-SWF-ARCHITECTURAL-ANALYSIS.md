 **Overview** The feature is to refactor Eucalyptus ELB to use SWF as a workflow orchestration service.

 **Context & Background** Distributed services often involve complex workflows and [[ELB|4.3-Investigation---In-VM-services-model-and-future]] is one such example. By using a common workflow engine (SWF), implementing the future Eucalyptus services (such as RDS) can be based on a well-known, repeatable pattern and their characteristics can be easily analyzed. When ELB is implemented in SWF, we can expect


* better scalability because periodic pollings are removed
* a simpler service configuration as the loadbalancing-backend service is removed
* a better instrumentation as all service events are recorded and accessible through SWF
* a reference service implementation using SWF

 **Requirements** 
## User Stories (Functional)
All existing ELB functionalities should be supported. The new implementation should achieve better (or at least the same) level of scale than the current ELB. The known scale limit can be found in [4.2 scalability evaluations](https://eucalyptus.atlassian.net/browse/EUCA-10517). Empirically, the changes should not affect the end user's experiences.


## Architectural Priorities & Constraints (Non-functional)

* The custom workflows should be re-implemented as SWF activities and workflows.
* The communication between ELB service and the ELB VM(haproxy) should be only via SWF (polling). The intent of communications should be clearly expressed as SWF workflows.
* The use of [glisten](https://github.com/Netflix/glisten) should be avoided.
* The 'loadbalancing-backend' service (in-memory state) should be removed and the 'loadbalancing' services should be horizontally scalable (as other UFS services do).
* The Flow-framework in aws-java-sdk is used for tooling (as it is officially supported by AWS).
* The current in-vm dependency injection mechanism should be used for any additional dependencies.


## Performance (Scale)
The scale of the new ELB service should be the same or better than the currently known scale limit. The ELB's use of SWF should not impact other services relying on SWF (e.g., cloudformation).

 **Analysis & Spikes** The investigation of In-VM services of which the ELB is an example can be found [[here|4.3-Investigation---In-VM-services-model-and-future]].

Investigation on SWF hardening is [[here|4.3-investigation---SWF-hardening]].


## SWF Scale
The current implementation of long-polling causes a major scale limit. During the scale test, it was found that only 10 ELBs can run concurrently when the UFS and CLC are distributed. The major problems identified are


* [client's thread pool size](https://eucalyptus.atlassian.net/browse/EUCA-12695)
* [service (mule) thread pool size](https://eucalyptus.atlassian.net/browse/EUCA-12691)
* [early return from long poll](https://eucalyptus.atlassian.net/browse/EUCA-12689)

Dependencies
* Netflix glisten no more actively maintained
* AspectJ load-time weaving works with Eucalyptus JVM.
* New jar libraries: aspectjweaver and jedis (redis Java client)
* aws-swf-build-tools.jar is needed to pre-process the flow-framework annotations and create the client stubs. This is not necessary for building Eucalyptus but required for developers to create the stub java files.


* New dependencies for load-balancer-servo: redis-server,java-1.8.0-openjdk,eucalyptus-java-common (eucalyptus + libs jars)




## VM Communication
In old ELB implementation, the VMs used a custom, non-AWS API to retrieve a loadbalancer's specification and put an instance status and cloud-watch metrics. They will be replaced with SWF task polling. IAM::downloadServerCertificate() will remain as the only non-SWF API from the VMs. The [[protocol|ELB-SSL-Specification]] for credential download will not be changed.

SWF WorkersEach ELB service (running on UFS) will run workers for decision tasks and activity tasks. Their client-side (e.g., thread pool size) setup is configurable via the properties.

Each VM (that runs haproxy for an ELB) will run an activity worker which is a standalone Java program.

RedisInside the ELB VMs, Redis is used as a simple interprocess communication between the SWF worker (Java) and load-balancer-servo (Python). The redis server listens on 127.0.0.1 (or domain socket can be used). There are only small amount messages exchanged via Redis.


## Service Configuration
Because SWF maintains ELB's service states and coordinates the access from distributed services, loadbalancing-backend (CLC) service can be safely removed. There will be 'loadbalancing' services hosted on UFS.

Security
* The existing [[protocol|ELB-SSL-Specification]] for credential exchange (to support downloading a user's server certificate) will not change. In summary,
    * A new RSA keypair is generated and passed down to the loadbalancer VM after encryption using NODE's keypair.
    * IAM service signs the keypair to certify that it can be used to download IAM user's server certificate
    * When a HTTPS/SSL listener is created, the loadbalancer VM requests iam:downloadServerCertificate with the public part of the keypair and the signature it generated in the step above
    * IAM uses the public key to encrypt the user's server certificate and VM decrypts and use it for the listener

    
* VM source IP checking is removed
* By default, non-admin accounts are restricted from using SWF. An ELB role is considered an admin and bypasses this restriction. (SimpleWorkflowMessageValidator).
* Credentials & permissions
* Default setting for Redis on rhel7 is used. The default setting listens only on 127.0.0.1.

    


## Milestones

1. Addressing SWF scale limit: we identified that SWF's scale limit is not acceptable for the ELB use-case. Addressing the scale problem precedes all future ELB developments.



References


1. [[4.3 investigation - SWF hardening|4.3-investigation---SWF-hardening]]
1. [[4.3 Investigation - In-VM services model and future|4.3-Investigation---In-VM-services-model-and-future]]
1. [https://eucalyptus.atlassian.net/browse/EUCA-10517](https://eucalyptus.atlassian.net/browse/EUCA-10517)
1. [https://github.com/Netflix/glisten](https://github.com/Netflix/glisten)
1. [EUCA-12689 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-12689)
1. [EUCA-12689 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-12689)
1. [EUCA-12691 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-12691)





















*****

[[tag:confluence]]
[[tag:rls-4.4]]
[[tag:elb]]
