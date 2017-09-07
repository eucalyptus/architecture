
# Architectural Discovery Checklist for Image Management (PRD-156)


Below, we assume that the overall story will be satisfied through an implementation of AWS Instance Import / Export APIs, with underlying Imaging Service (IS) and Imaging Toolkit (IT) added to Euca to perform the work of these operations.


# Dependencies

* Features (external to this feature)
    * Existing

    


* 
    * 
    * Object storage (Walrus) - permanent repository for images, new and converted
    * Hypervisor storage (NC/Broker) - converted images must find their way there

    

    


* 
    * In Progress
    * Missing

    If unbundling is performed by this new Imaging Service, implementation of GetDecryptedImage in Walrus would have to change (perhaps moved to Imaging Service)
    * Software
    * Libraries

    

    

We may end up relying on many external libraries/tools for:


* 
    * 
    * 
    * driving conversion / validation steps
    * performing disk image conversions

    

    

    

Specific dependencies will be part of the exploration spike




* 
    * 
    * Services (external)

    

    

No external services are needed. AWS Instance Import/Export service can be used to check compatibility and understand semantics of the service to ensure compatibility, at least with respect to Windows instances.

Interfaces




* APIs

External API matches AWS Import/Export service API


* 
    * S3 operations (put, get, etc)
    * ImportInstance
    * ImportVolume
    * DescribeConversionTasks
    * CancelConversionTask
    * CreateInstanceExportTask (future?)
    * CancelExportTask (future?)
    * DescribeExportTasks (future?)

    

Since the plan is to go beyond AWS semantics and support Linux image and partition ingress via InstanceImport, we may need to decide on how to pass a few additional parameters to the Imaging Service in an AWS-compatible way. E.g., when ingressing images, it may be necessary to specify:


* 
    * kernel & ramdisk to associate with the resulting EMI (Possibly add it to manifest?)
    * hypervisor type (paravirt | hvm) (???)
    * image layout (disk | partition) (Possibly covered by ImportInstance.DiskImage.n.Image.Format)
    * operating system (linux | windows) (Covered by ImportInstance.Platform)
    * whether to run the instance or just stop at a registered EMI (Possibly covered by ImportInstance.LaunchSpecification.Placement.AvailabilityZone)
    * instance backing type (instance store | EBS) (Covered by ImportInstance.DiskImage.n.Volume.Size)

    

Internally, multiple new services, each with its own API, may be added, once the design is solidified (e.g., Imaging Toolkit, "Image Transport" Service)


* Clients


* 
    * {euca | ec2}-import-instance
    * {euca | ec2}-import-volume
    * {euca | ec2}-describe-conversion-tasks
    * {euca | ec2}-delete-disk-image
    * {euca | ec2}-cancel-conversion-task
    * {euca | ec2}-create-export-task (future?)
    * {euca | ec2}-describe-export-tasks (future?)

    


* Configuration

Imaging Service will be registered with EC2 Service and possibly configured in a load-balanced configuration (more than one IS in the system). Imaging Service itself should be configurable in term of:


* 
    * Limits on concurrent imaging operations
    * Location of the Imaging Toolkit (defaults to location used by packaging)
    * Possibly: location of the object service (OSG or Walrus) to read / write from, although that may be part of EC2 service configuration

    

Imaging Toolkit should be configurable in term of:


* 
    * Storage to be used as scratch space, during conversions and transfers (Local Work Cache)
    * File system location
    * Limit on how much scratch space is used

    
    * Limits on CPU or I/O parallelism inside the Imaging Toolkit

    


* Formats
    * Authentication
    * Signatures

    Standard AWS / Euca signatures

    

    
* Logs

    Standard log locations most likely (Imaging Service to cloud-output.log, Imaging Toolkit to imaging.log or something like that)
* Persistence
    * Databases

    Possibly two new tables

    


* 
    * 
    * EC2 service: Import / Export task state
    * Imaging Service: conversion / validation task state

    

    


* 
    * Filesystems

    Imaging Toolkit will need work space (with cacheable objects) on the file system or possibly a raw block device. Disk usage must be subject to limits.

    
* Services
    * Administrative

    None planned
    * SOAP / Query / REST APIs

    Nothing extra beyond EC2-compatible APIs listed above

    


# Errors

* Conditions

Currently anticipated error conditions include:


* 
    * Imaging Service is missing Imaging Toolkit => service will be disabled
    * Imaging Toolkit is missing a dependency => the toolkit will fail the specific operation that requires the dependency (e.g., lack of VMware libraries may prevent VMware Broker from working, but it should not prevent other conversions)
    * Storage limit is exceeded (or physical storage is not available) => operations that require additional storage will fail

    


* Functional Degradation

    If multiple instances of the Imaging Service are present, failure of one should be handled by directing future imaging requests to the other one.
* States


* 
    * EC2 Export / Import ops will report task state, which is related to
    * Imaging Service workflow state, which is related to
    * Progress status & result (success / failure) from an Imaging Toolkit invocation

    


# Security

* Authentication and access control

    Standard AWS-style authentication for the user-facing service. Standard internal Euca authentication for the Imaging Service. (As for any other cloud-level component.)

Vika Felmetsger:It would be great if IS had more fine grained access control for NCs than currently (when each NC has "admin" access to all images/objects on Walrus)


* Data
    * At Rest

    

Image bundles in Object Storage may be encrypted (that's the standard for bundles that come from users) or may be unencrypted (for bundles to be used internally, prior to transfer of the image to hypervisor-local storage). Image contents in Imaging Toolkit work cache will be unencrypted for analysis.



Vika Felmetsger:Linux permissions to protect data on filesystem


* 
    * In Flight

    

If only encrypted bundles are stored in Object Store, then in-flight data will also be encrypted (it will be up to the consumer - Imaging Service or the hypervisor - to decrypt the bundle). However, if we allow for storage of unencrypted bundles, then unencrypted images will be transferred.



Vika Felmetsger:To consider:


* 
    * SSL for image/bundle transfer
    * checksums for transferred images/bundles

    


* 
    * Network and message security

    




* 
    * External Services

    

Delivery


* Deliverables

New RPM packages:


* 
    * Imaging Service (at least one of which is required in the system)
    * Imaging Toolkit (pre-req of Imaging Service, but also usable alone)
    * Imaging Toolkit enterprise version (e.g., VMDK converters, if they cannot be distributed in the open)

    

There is the question of whether the Imaging Service (with the Imaging Toolkit alongside) should be distributed as a VM, in the way the ELB Service is. There are advantages to that, but this additional level of packaging/flexibility has its cost.


* Distribution

    Standard Euca repos
* Packaging

    Imaging Service will need an init script, which should ensure presence of the Imaging Toolkit on the system. The toolkit will consist of many scripts, organized on a file system into a rigid structure, with many dependencies, but no daemon. The Imaging Service will run inside a JVM, like many other Euca components.


# Development

* Build

    Imaging Service and Imaging Toolkit are to build with the core of Eucalyptus. Additionally, Imaging Toolkit should be buildable independently. Complications:


* 
    * The Toolkit's build will need to be integrated into core Euca build (as a module?)
    * Some parts of the Toolkit may involve proprietary / hard-to-distribute libraries (e.g., VDDK)

    


* Expertise

Wide-ranging expertise is required for this project: services, storage, back-end, tools, scripting.

Misc notes (which didn't fit anywhere else on this checklist):


* 
    * If object store is to keep streamable versions of images (ready for decryption on the fly, without any additional manipulations necessary on the hypervisor host), we should consider:
    * Making key injection on BE either disabled by default or unsupported
    * We may want to consider deprecating m1.small disk layout

    
    * Crazy idea: add support to the Storage Controller for temporary remote backing stores (e.g., raw partition on the NC) and provision Instance Store instances with the same logic as EBS.

    


* Language

    Java: Imaging Service, any other needed services

    C: Changes on the NC

    Python: Imaging Toolkit

    Others: may be used to develop stages usable in the Imaging Toolkit


# Resources

* Hardware
    * Availability
    * Configuration

    Imaging Service is expected to be able to run fully independently (of any other Euca component), possibly with multiple instances for load-balancing. Therefore, there may be new QA configurations: stand-alone IS, two ISs in load-balanced configuration.
    * Software

    VMware's VDDK (with an on-going TAP program management, to allow us to distribute it) may be needed for VMDK conversions / uploads within the Imaging Toolkit (the way they are now needed for euca_imager today).
    * Teams

    


* 
    * 
    * Services (Imaging Service, integration with Storage, integration with Toolkit)
    * Storage (integration with Imaging Service, reworking of GetDecryptedImage)
    * Tools (Imaging Toolkit itself and its reliance on existing euca2ools)
    * Back-end team (possible NC / VB work if GetDecryptedImage changes)

    

    


# Risks

* Areas of greater than usual complexity

    Imaging Toolkit is a relatively new kind of entity in Eucalyptus (a set of tasks, composable into workflows, executable within and without Euca). Existing architectural approaches may not be applicable here and approaches to integration with existing code-base (both in terms of build, packaging, and execution) are unclear as of now.
* Unknowns

    There are a number of unknown unknowns in this endeavour.


# References

* Specifications (external)


* 
    * [PRD-124](https://eucalyptus.atlassian.net/browse/PRD-124)(a child of umbrella PRD for image management:[PRD-156](https://eucalyptus.atlassian.net/browse/PRD-156))
    * Epic:[EUCA-6645](https://eucalyptus.atlassian.net/browse/EUCA-6645)(Items that fall under the Image Management and BE team)
    * 3.4 arch spec:[Image Management 3.4 spec on github](https://github.com/eucalyptus/architecture/wiki/image-management-3.4-spec)

    

Potential mega-stories (smaller stories are already in EUCA-6645):


1. \[S] Bare-bones import service for IS HVM images, without Imaging Toolkit
1. \[S] Remove image decryption and reassembly from Walrus into Imaging Service
1. \[M] Tools work to support VM Import / Export Service
1. \[L] Import service for Linux and Windows IS and EBS partition and disk images
1. \[M] Import and conversion of VMDK images
1. \[S-L] Implementation of Linux and Windows static and dynamic validators
1. \[M] Cross-backing-type recycling (bundle-instance for EBS, create-image for IS)
1. \[M] Deployment of Imaging Service in a load-balanced VM
1. \[S] Imaging Toolkit workflow invocation outside Euca

Where


* S = 1 sprint worth of work (for 1 or more person)
* M = 2 sprints…
* L = 4 sprints

Notes:


* Vic: make it a developer task to write automatic test for functionality as it is implemented
* Neil: storage team is busy, so addition of #2 may kick something out of their schedule



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:image-management]]
