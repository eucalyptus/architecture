 **Overview** Block storage in Eucalyptus must be extensible to 3rd party systems without requiring development of plugins that have symbolic references or compile/link dependencies on the rest of Eucalyptus (Java or C code)

 **Functional Requirements** 
1. Stand-alone usage/testing of any given EBS plugin without any of Eucalyptus running or compiled.
1. Full EBS capability for volumes, snapshots, and volume migration between hosts (for vm migration)
1. Configuration based on configuration files possibly specific to each plugin
1. Clearly defined logging endpoints/output, not necessarily the same as Eucalyptus itself
1. Includes all necessary operations for both SC and NC:
    1. Create Volume
    1. New volume
    1. From existing snapshot on same backend
    1. From some data locally (file or block device)

    
    1. Delete Volume
    1. Create Snapshot from volume
    1. Attach volume to local host
    1. As block-device
    1. Optionally as other types (e.g. KVM device)

    
    1. Detach volume from local host
    1. Same constraints as Attach

    

    
1. Ideally, would allow leveraging of existing plugins for OpenStack
1. Must support per-host authentication and access-control at a volume level.
1. Must support iSCSI and MPIO capabilities

 **Architecture Constraints** 
* Plugins must be stateless


* Plugin operations must be idempotent


* Plugin/Adapter must be as asynchronous as possible to not block on long-lived operations (e.g. snapshot clone, etc). Should use polling rather than blocking

 **Architectural Components**  **Pluggable EBS Arch Components** 

Block Storage Provider (BSP)
* Provides data persistence and a block storage interface.
* Examples: Netapp SAN, Equallogic SAN, Ceph RBD, LVM w/TGT/LIO

Block Storage Adapter (BSA)
* Interacts with a specific BSP
* May have non-euca dependencies (cli’s, libs, etc)
* Independently executable via some API (e.g. python script invocation

Eucalyptus Storage Tools
* Human and computer usable interface to interact with BSPs via a specific BSA
* Must be script-invocable, but can be optionally interactive
* Presents a single, common API regardless of BSA/BSP
* Well defined input/output, should be easily parsed by machines
* Must be human readable, but not as primary usage (e.g. json or xml is okay)
* Must require specific credentials for various operations (SAN operations should require those credentials, local host attach/detach should not require SAN credentials)
* Example: usage on the NC should not permit volume create/delete operations, only attach/detach
* Example: usage on the SC should allow both CRUD and attach/detach operations by providing proper credentials
* Does not require Eucalyptus user credentials—system credentials should be sufficient

Storage Controller (existing SC, not new)
* Implements a SOAP API for Eucalyptus-internal operations for block storage


* Responsible for EBS entity state management at the resource level
* Does not implement the EBS API directly.
* Not user facing
* Depends on the EBSC to actuate state changes on a specific backend. Invokes the EBSC directly.



Node Controller
* Depends on the EBSC to actual attachment changes on the local host, but must not be permitted to do CRUD operations on resources directly
* Depends on the SC to get input necessary for EBSC attach/detach operations

 **Suggestions/Thought-experiments** EBSC as a single executable/script that uses command line parameters or stdin for input and outputs JSON/XML

 _>euca-block-console -bsa=netapp -op=createvolume -size=1024 -name=vol-123abc -src=none_ —>

{

“status”: { “result”: “ok”, “duration”:”300ms" },

“volume”: { “name”: “vol-123abc”, “size”: “1024000mb”, “creation-date”: “12-02-2014T12:10:03.000”, “path”:”vol-123abc”},

}



 _>euca-block-console -bsa=netapp -op=exportvolume -dest=10.111.1.1 -dest-id=iqn-123abc456 -interfaces=“ip1 ip2 ip3”—>_ 

{

  “status”: { “result”:”ok”, “duration”:”900ms”},

  “export”: {

     “volume”: “vol-123abc”,

     “size”:

     “iscsi": {

       “target”: “[iqn-20081015.netapp.com](http://iqn-20081015.netapp.com):12”, “resource”: “lun1”, “chap”: “user123:dbcfff350909808a9”

     }

  }

}



 _>echo '{“export”: {….} }’’}' |euca-block-console -bsa=netapp -op=attachvolume—>_ 

{

  “status”: { “result”: “ok”, “duration”: “1200ms”},

  “device”: “/dev/sdc”

}









*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:ebs]]
