Architectural Discovery Checklist


PRD-77


=================================



Checklist to help identify items of architectural interest with


regards to feature scope. This should also help to identify areas that


require investigation.



It is expected that most items listed are not relevant for a given


feature (are not of interest at this time). The aim is only to help


identify areas that are of particular interest for scoping. The list


should not be filled out for a feature, only the parts of interest would


be used.





Dependencies


* Features (external to this feature)
* Existing


* 169.254.169.254 metadata service


* Software
* Libraries


* ipsets, ebtables


    
Interfaces


* APIs


* either pull/push of structured network metadata to eucanetd


* Configuration


* eucanetd requires several configuration options (site-specific)
* mechanism for configuring eucanetd undecided (config files, pushed from CLC, etc)


* Formats


* use structured data format to describe network runtime meta-data


* Logs


* eucanetd.log, same facility as other back-end components (CC/NC)
* hook into fault subsystem, define faults


* Persistence
* Filesystems


* eucanetd use local state files to cache remote network meta-data information
 

    
Errors


* Conditions


* network partitions can effect reciept of current network view
* incorrect network configuration by user is not detectable


* Functional Degradation


* collection of eucanetd attempt to implement global network view, can interfere with eahother if global view is not in sync accross eucanetds


* States


* independent of eucalyptus component states, eucanetd will attempt to implement last good network view


    
Security


* Authentication and access control


* host-based accessVika Felmetsger:

    
We'll need something stronger to authenticate communicating components to make sure metadata comes from a trusted component and to the expected ones
* use standard UNIX user/filesystem permissions for local security
* information cached in local state files


* Data
* In Flight


* Sensitive network metadata needs to make it from CLC to all NCs, securely


* Network and message security


* Review of L2 isolation rules (ebtables) to ensure both correctness and fidelity with AWS


    
Delivery


* Deliverables


* new RPM package with eucanetd


* Packaging


* init script for eucanetd
* eucanetd binary
* ensure eucanetd package has all the right dependencies


* Platform


* RHEL 6.3++ for ipsets


    
Resources


* Teams


* Back-end team / networking
* Services team
* QA Team (new automated QA infrastructure required for testing)


    
Risks


* Areas of greater than usual complexity


* QA Software requires modification to test new network topologies
* switching networking modes (to EDGE) requires instance termination - if this needs to be remedied, scope is very large


* Unknowns  \* VPC requirements unknown


* VMWare + EDGE support
* work required here may lead to re-implementing existing network modes using new EDGE model


    
References


* Specifications (external)


* AWS networking semantics (L2, L3 behavior, isolation, default sec. group policies)


    
Notes
* may have fast-start benefit/implications


    

    

    



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:networking]]
