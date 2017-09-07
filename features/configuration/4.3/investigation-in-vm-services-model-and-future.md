
# PROBLEM
Beginning with ELB, Eucalyptus has implemented various in-VM services where a part of the service's task is contained, coordinated, and executed in VMs. They are ELB, Imaging, and remote database service (not officially released). Although this architecture brings many benefits, such as horizontal scalability, simpler life-cycle management, and secure containment, the lack of architectural definition creates problems such as


* Repeatability: compared to other services, creating In-VM service requires extra effort, many of which are largely duplicate of the existing services
* Security: many security bugs have been found late in the release, probably due to the difficulty of security audit
* Troubleshooting & debugging


# GOAL
The goal of this investigation and the future works are to 1) present the current architecture of the In-VM service, 2) identify the problem areas, 3) and to refine/modify the architecture to make the process repeatable for new services.


# EXAMPLE USE-CASE
The best well-known use of the In-VM service is the implementation of ELB. From its early discussion, ELB required horizontal scalability as the number of concurrent ELBs in the system is unknown yet it should be considered scalable. The ELB's implementation as In-VM service can be summarized as follows:


*  **ELB service setup** : There is a EUCA-released package that contains the Centos image in which the daemons for various in-vm services (e.g., ELB, imaging, db) and the third-party packages (e.g., haproxy, postgresql) are pre-installed.ELB service's availability depends on the registration of the EMI.
*  **ELB life-cycle** : When a new ELB is created, the ELB service creates an autoscaling group that manages VMs spun off the configured service EMI.There is a system-wide property that determines how many VMs should be created per ELB. When the ELB is deleted, the corresponding autoscaling group is deleted and all its VM instances are terminated.
*  **DNS resolution** : The created loadbalancer is accessible using its DNS name. The DNS resolver looks up the list of VMs that belong to the queried ELB and returns its public IPs in the round-robin manner.
*  **Managing haproxy** : There is a python daemon running in the VMs. The daemon communicates with the ELB service to receive specification of the ELB (e.g., protocol, port, list of backend IPs). When the VM is started or there is a change in the ELB's specification, the daemon prepares the configuration of haproxy and manages life-cycle of the process.
*  **Security** 
    * All internal resources implementing an ELB are owned by ELB system account, which inherits super-user privilege of 'eucalyptus' account. To restrict the VM's access to only relevant resources, IAM role with a limited IAM permission is granted to the VM. For example, the VM is given permission to call a specific internal ELB API to retrieve the ELB's specification.
    * There is a security group per ELB that authorizes access to only protocol-port that is defined in the ELB's listeners.
    * To implement HTTPS/SSL listeners, a server certificate containing a private key should be delivered to VMs via a non-encrypted transport. The delivery of such confidential information requires another credential that is securely seeded in the VM and used to encrypt the private key of the server certificate. We implemented a custom protocol to seed the credential in the VM, as explained in detail here:[[ELB SSL Specification|ELB-SSL-Specification]]

    
*  **Service polling and pushing:** The in-vm daemon continuously polls ELB service to find any update to the ELB's specification and to make subsequent changes to Haproxy. There is also periodic pushing by which the health-status of backend instances and the cloud-watch metrics are reported to the service.
*  **Property changes** : There is a set of properties that affects all ELBs in the system. Examples include ssh-key for debugging VMs, number of VMs per ELB, and the polling and pushing interval to regulate the performance impact. When the property is changed, the autoscaling groups of all ELBs are updated. However the existing VMs are not affected by the change and it requires manually terminating the VMs to refresh the ELBs.


# COMMON PATTERNS AND ISSUES

1.  **Workflow for creating resources** 

    There are sequential steps each of which creates a resource (e.g., autoscaling group, IAM role, etc). The final artifact of such workflow is the bundle of resources that implements the service (e.g., Autoscaling Group, IAM role, IAM policy, and security group). When there is a failure in one of the steps, the whole workflow is rolled-back, deleting the resources created up to that step. In each step of the workflow, API is invoked on other EUCA services, such as EC2 and IAM, to create the resources. There are known issues in the pattern:
    1. Clients for calling other EUCA services live within the particular service module (e.g., ELB, Imaging, DB). This is largely a duplication of the same functions. There should be one module that implements the clients for all EUCA services ('euca-resources-support' is the module in 4.2).
    1. The workflow is not reusable for different in-Vm services, although many steps of the workflow are duplicate among the services. The new services should be able to compose the existing, reusable activities into a new workflow. SWF can be the framework to achieve this.

    

    

    
1.  **System account to own resources** 

    For each In-VM service, there is a special system account that owns the resources the service creates (e.g., '(eucalyptus)loadbalancing' for ELB). All API invocation for internal services are done as the system account of the service. This allows the cloud-admins to have a separate view of the resources that each service consume and manages them accordingly. The known issues are --
    1. In EUCA's auth/authz subsystem, a system account inherits the privileges of the 'eucalyptus' (root) account. This violates the 'least privilege principle'. Although each service uses IAM role policy to restrict the permissions given to the VMs, there is still a security concern because the service and the cloud-admins can access to unintended resources.

    

    

    
1.  **IAM role to delegate permissions** 

    When a new service instance is created (e.g., ELB), the service workflow creates a new role (and instance profile) for the instance. The assumeRole policy of the role gives the permission (to obtain short-lived credentials) to EC2 service so that the python in-VM client can obtain the role credentials to interact with the EUCA services. The system account discussed above owns all roles and instance profiles. Later in the workflow the instance profile is attached to the autoscaling group, thereby all VMs in the scaling group can assume the role. The python client in the VM uses 'boto' to obtain the role credentials delivered via instance metadata.

    

    
1.  **VM as stateless container** 

    At the end of workflow, an autoscaling group is created that manages all VMs for the service instance. For example, when a new ELB is created, the autoscaling group for the ELB is created for each availability zone the ELB intends to serve. The management of VMs is delegated to the autoscaling group and the service does not directly manage the VM's lifecycle. The service runs several timer-based threads that checks the attributes and status of the VMs. For example, ELB checks the IP address and the status of VMs when it populates the IPs for resolving the ELB's DNS name. The interaction between the service and the VMs (the python daemon more precisely) can be modeled as a simple Master-Worker pattern. The service (master) prepares tasks (e.g., imaging conversion, haproxy process, PostgreSQL process), which is taken by VM workers, without a specific binding between the task and the worker through a complex scheduling. During the service, there is no coordination between the workers. The VMs are considered stateless, meaning that they can be simply replaced by new VMs via EC2/Autoscaling group API, or more VMs can be dispatched if the service should handle more loads.

    

    
1.  **Properties and parameter passing to VMs** 

    The python daemon in the VM is given parameters to configure the environment and the process it manages. There are 2 ways to deliver the parameters:
    1. User-data: system-wide properties such as ELB's polling interval and NTP server address is delivered via instance user-data
    1. Service API: resource-specific parameters are delivered in the response of the service API (called by VM client).

    There are known issues in the current mechanisms:
    1. Updating global properties require editing **all**  ofthe launch config and the autoscaling group in the system to update the instance userdata. This area of code is complex, confusing and error-prone.
    1. The existing VMs need to be terminated in order to refresh the VMs with the new parameters. This may introduce service interruption.

    The problem is due to the use of user-data as the delivery mechanism, but the service's API is not a good place for passing the parameters either because we don't want to introduce non-AWS, service-specific APIs in the system. We need a service-agnostic, dynamic way of passing the parameters to the In-VM daemon.

    

    
1.  **Credential distribution** 

    Many services use IAM server certificate to encrypt the services it offer. For example, ELB uses IAM server certificate to provide SSL termination at the loadbalancer. Remote-database service uses a server certificate to encrypt a DB instance's password passed to the VM. As discussed above in the ELB use-case, we implemented a custom protocol to seed a certificate in the VM which is used to encrypt and decrypt the IAM server certificates. There are issues in the current approach:
    1. The implementation is not well-defined and documented. Currently, the services (ELB, Imaging)  **signals** EC2 via injecting a hard-coded user-data to initiate the certificate distribution protocol. This is mainly due to the lack of interface to implement such non-AWS functionality in 'runInstances' API, but it results in a undocumented, hard-to-understand codes in CLC, CC, and NC
    1. The certificate seeded in the VM is not properly managed. When it is expired, the service cannot transport the server certificates to the VM anymore and it does not give any warning to the users.

    

    

    
1.  **Python in-vm daemon** 

    The python daemon running inside the VM interacts with the services to:
    1. manage life-cycle of a standalone process (e.g., haproxy, euca_imager, postgred)
    1. parse EUCA requests into the input specification of the standalone process

    The service API is extended (often by modifying the existing API) to deliver the parameters to the in-VM daemon and this internal API invocation goes through the same REST pipeline as the other public services. In other words, the VMs can be considered a EUCA client. The communication is based on polling, by which the daemon pulls the latest information about the service and pushes the status information (e.g., health check, cloud-watch metrics) to the service in every fixed interval. In 4.1., we had the scalability issue with ELB due to the frequent polling by daemons. To fix it, we introduced the configurable polling interval as properties. There are several issues with the current approach:

    
    1. As discussed, polling causes scalability issues that can affect the whole cloud
    1. Extending AWS service is not desirable
    1. To invoke the extended service API, some 'boto' classes are extended and used by the daemon. This is a tedious process that should be done for every new in-VM service
    1. The service 'client' codes, such as downloadServerCertificate, are duplicated among different services. There is no client library that can be shared by in-VM services.

    


# MISC ISSUES

*  **VPC internal network** 

    The VMs running in a private subnet is not functional and this blocks internal ELB. When addressed, running VMs in private subnet would make the In-VM services more secure and efficient (i.e., consume no public IPs).


# TOWARD REPEATABLE IN-VM SERIVCES

1.  **Re-write service and python daemon in SWF** 
    1. The same service, but reusable workflow, workers, and deciders.
    1. Address the parameter-passing issue
    1. Address non-AWS service API issue
    1. Address extended 'boto' and duplicate python client issue
    1. Can it address the performance problem too? or make it worse?

    
1.  **Address the certificate management problem** 
    1. Especially the expired certificate will be a major problem

    
1.  **System account?** 





*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:configuration]]
