
# Overview
Eucalyptus needs a distributed, scale-out block storage solution. Ceph provides such a system via its RBD interface. Eucalyptus will integrate with Ceph to provide block-storage services for the Eucalyptus EBS service, which exposes block devices to VM instances for persistent block-level storage.


# Tracking

* [ARCH-88 (Ceph RBD integration)](https://eucalyptus.atlassian.net/browse/ARCH-88)
* Relates to modular ebs plugins, indirectly[ARCH-87: Pluggable EBS backends](https://eucalyptus.atlassian.net/browse/ARCH-87), but is not blocked by it, nor is ARCH-87 dependent on this.


# Use Cases

1. Configure eucalyptus to host EBS volumes/snaps on a Ceph cluster
1. Continue to support instance migration between hosts with attached EBS volumes
1. Add EBS capacity without service interruption
    1. Accomplished via: add host to ceph cluster

    
1. Handle host failure without service interruption
    1. Accomplished via: standard ceph practices for failure handling

    
1. Stretch: Pool my NCs' local storage to host EBS volumes/snapshots
    1. Use dedicated disks and nics on NCs to create Ceph pool

    


# Functional Requirements

1. Provide EBS-compliant abstractions to the other services: SC and NC
    1. Snapshots must persist past the life of their source volumes
    1. Volumes created from snapshots must be completely lifecycle-decoupled

    
1. The system must provide the NC with a block device that can be exposed to a VM
    1. Linux system block device or
    1. Direct device consumable by KVM

    
1. VMWare support: optional. VMware only interfaces with CIFS, NFS, and iSCSI
1. Add storage capacity with zero downtime
1. Handle cluster host failure without downtime to the storage system itself (HA SCs and Ceph cluster provide this)
1. Support instance migration between hosts: block device must be attached and writable from both source and destination simultaneously


# Domain Model
Eucalyptus and Ceph Elements






1. Ceph Cluster - The ceph system addressable by a specific endpoint that provides storage
1. Ceph Storage Pool - A specific collection of capacity identified explicitly via 'rbd create pool' that provides a storage scope for names and capacity
1. Ceph RBD Image- An image that can be used as a block device
1. Ceph Snapshot - A read-only copy of an image. Can be used as a source for other snapshots or images. Ceph snapshots have multiple states that may make the relationship from Euca to Ceph snapshots change with multiplicity from one-to-one to one-to-many depending on the metadata management strategy implemented (see:[http://ceph.com/docs/master/rbd/rbd-snapshot/](http://ceph.com/docs/master/rbd/rbd-snapshot/))
    1. Regular snapshot: read-only. Can be snapshotted again, but requires being 'protected'
    1. Protected snapshot: cannot be deleted. Must be in this state to create a child snapshot
    1. Child/Cloned Image: a cloned snapshot that copies the data from the parent, but retains a link to the parent and is writable
    1. Flattened Cloned Image: explicitly copying the parent data and removing the relationship between parent snapshot and child cloned image.

    


# Architectural Components
Eucalyptus NC and SC Ceph Interactions


1. Storage Controller - Eucalyptus component that provides EBS services to a specific Eucalyptus cluster
    1. Storage Controller manages the entire lifecycle of Ceph images and snapshots. This is consistent with all other backend providers for EBS.

    
1. Node Controller - Eucalyptus component that provides VM/instance services to a Eucalyptus cluster. A cluster has many of these.
    1. Node controller manages the attachment of the ceph block device to VM from which it will be accessed. This is consistent with the current EBS architecture.
    1. For instance migration, a block device must be attached to both source and destination NC simultaneously.

    
1. Ceph Cluster - A collection of hosts that provide, in aggregate, storage as a service. Provides Object, Block, and FS services. We leverage only Block in this case.
1. Ceph Storage Pool - A subset of hosts in a ceph cluster that provide a specific capacity for storage and a configuration space as well as namespace for images.
1. Ceph RBD driver - A kernel module that provides RBD block devices from the kernel
1. Ceph KVM driver - A Qemu/KVM driver to provide RBD devices directly to VMs without kernel modules required, the driver is a client of Ceph itself
1.  **Eucalyptus Storage Utils** 
    1. A standalone set of tools/library that takes input from the result of Export/Unexport calls to the SC and performs the necessary attach/detach operations to expose a block device to a specific VM instance.
    1. Invoked directly by the NC. Independently testable (given sufficient input, should not require any internal NC state to operate)
    1. Removes need for NC to know details of attach/detach for any backends
    1. Must implement both iSCSI (plus MPIO) and Ceph operations
    1. Future EBS plugins are implemented purely here

    
    1. Eventually, will be leveraged on the SC for all volume/snap operations, but for 4.1, only attach/detach on the NC/SC (for snapshots)
    1. For Ceph:
    1. Must support direct KVM/libvirt attachment

    

    




# Security Considerations

* Ceph credentials are persisted on SC and NC as Ceph keyring files (/etc/ceph/ceph.client.username.keyring),must be secure
    * SC - keyring file should be owned by root user and eucalyptus group with file permissions set to 640
    * NC - keyring file should be owned by root user and kvm group with file permissions set to 640

    
* SC and NC should use different Ceph credentials with necessary privileges -[[Ceph User Permissions For EBS|Ceph-User-Permissions-For-EBS]]
* Eucalyptus User credentials - Never required.
* Ceph's RBD command-line interface may expose its credentials in process info as command args. Must ensure safety.


* Ceph provides 'cephx' authentication mechanisms. Without these there are no access controls. See:[http://ceph.com/docs/master/rados/operations/authentication/](http://ceph.com/docs/master/rados/operations/authentication/)
* Ceph's access control system is very coarse grained. It grants access on a per-pool basis, so there is no way to isolate specific images or snapshots


## Security Model With CephX

* Reference:[http://ceph.com/docs/master/rados/operations/auth-intro/](http://ceph.com/docs/master/rados/operations/auth-intro/)[http://ceph.com/docs/master/rados/operations/authentication/](http://ceph.com/docs/master/rados/operations/authentication/)
* Each host in a Eucalyptus cluster will map to a unique user in the CephX system.
* NCs will have read, write capabilities via libvirt-qemu driver to librbd
* SCs will have create, delete, snap, read, write capabilities via JNA bindings to librbd
* Possible security design
    * Ensure NCs only have access to the volumes that are attached, we will use full disk encryption at the NC level with keys managed by the SC and matched to the lifecycle of the volume. The caveat is that this will require the same key for all snapshots based on that volume and all volumes derived from such snapshots. Thus a key for the original volume becomes the key for the volume tree rooted at that volume.
    * Use dm-crypt on the NC in combination with Ceph's Kernel module access to provide rbd block devices that are full-disk encrypted.
    * This is not a viable option in the current state of Ceph due to the kernel module's lack of features and stability. We currently use only the qemu driver for presenting the device to VMs and that does not support dm-crypt directly.

    

    


# Interfaces

## Ceph<-->Storage Controller
Using JNA bindings for librbd directly. Could use librbd (C/C++/Python) and/or 'rbd' command-line.



| EBS operation | Ceph operation(s) and corresponding rbd command(s) | 
|  --- |  --- | 
| Create volume | EBS volume -> rbd imageCreate image: rbd --id <username> --keyring <path-to-keyring-file> create <pool>/<image> --size <size-in-MB> --image-format 2 | 
| Create snapshot from volume | 
1. EBS snapshot -> rbd dest-image, EBS volume -> rbd source-image
1. Create rbd snapshot on source image: rbd --id <username> --keyring <path-to-keyring-file> snap create <pool>/<source-image>@<snapshot>
1. Protect rbd snapshot on source image: rbd --id <username> --keyring <path-to-keyring-file> snap protect <pool>/<source-image>@<snapshot>
1. Clone destination image using rbd snapshot on source image: rbd --id <username> --keyring <path-to-keyring-file> clone <pool>/<source-image>@<snapshot><pool>/<dest-image>
1. Create rbd snapshot on destination image: rbd --id <username> --keyring <path-to-keyring-file> snap create <pool>/<dest-image>@<snapshot>
1. Protect rbd snapshot on destination image: rbd --id <username> --keyring <path-to-keyring-file> snap protect <pool>/<dest-image>@<snapshot><ul><li> _This is the snapshot that will be used in the "Create volume from snapshot" operation below._ </li></ul>

Sequence diagram | 
| Create volume from snapshot | EBS volume -> rbd dest-image, EBS snapshot -> rbd source-imageClone destination image using rbd snapshot on source image: rbd --id <username> --keyring <path-to-keyring-file> clone <pool>/<source-image>@<snapshot> <pool>/<dest-image>Sequence diagram | 
| Delete volume | EBS volume -> rbd image Rename image with known prefix: rbd --id <username> --keyring <path-to-keyring-file> rename <pool>/<image> <pool>/<prefix-image>Refer to async process that actually removes rbd images | 
| Delete snapshot | EBS snapshot -> rbd imageRename image with known prefix: rbd --id <username> --keyring <path-to-keyring-file> rename <pool>/<image> <pool>/<prefix-image>Refer to async process that actually removes rbd images | 
| Attach volume | No op (get connection information: includes opaque uuid for encapsulating cephx keyring on NCs, no export action required for ceph) | 
| Detach volume | No op (no-op for ceph on SC) | 


### Create snapshot from volume (euca-create-snapshot)
create_snapshot_from_volume


### Create volume from snapshot (euca-create-volume --snapshot)
create_vol_from_snap


### Delete volume or snapshot
Deletion of EBS volumes and snapshots is a two step process for the ceph-rbd provider


1. The first step is when ceph-rbd provider receives a delete request for an EBS volume/snapshot. The provider renames corresponding rbd image with a specific prefix. If the renaming succeeds, the EBS volume/snapshot is marked as deleted in Eucalyptus (SC and eventually CLC)
1. The second step involves a worker thread in ceph-rbd provider scanning Ceph pools for all images with specific prefix. Images marked for deletion are checked for clones/children. Only images with no clones are removed from the ceph pool. If an image has any children it is left untouched until all its children are deleted. This is an async step that runs periodically (every minute)

    image-deletion-flow-chart


## Ceph<-->Node Controller
Currently using Libvirt:


* Special disk/volume type in libvirt:


```
<disk type='network' device='disk'>
        <source protocol='rbd' name='libvirt-pool/new-libvirt-image'>
                <host name='{monitor-host}' port='6789'/>
        </source>
		<auth username='username'>
        	<secret type='ceph' uuid='{virsh-secret-uuid}'/>
      	</auth>
        <target dev='vda' bus='virtio'/>
</disk>
```

* Using a libvirt secret since CephX authentication is used
* NC is unaware of Ceph and remains mostly unchanged.
* Connection perl scripts have been modified to perform the iscsi/Ceph operation and output the xml content required for connecting to the storage resource through libvirt. 

Other options:


* librbd (C/C++/Python) and/or 'rbd' command-line using rbd kernel module to mount the ceph image as a block device:map, unmap image
* Optional: NC change to leverage Storage Pools in libvirt for iscsi & rbd rather than single disks:[http://libvirt.org/storage.html](http://libvirt.org/storage.html)
* Eucalyptus storage utils to replace connection perl scripts


## SC <-> NC
SOAP messaging as per current euca architecture. No expected changes in mechanism though message specifics will likely change.

The current 'connection string' must either become completely opaque or more well defined if NC must parse it. Current implementation of EBS does not require the NC to parse, just pass along to the tool that does iscsi operations (perl script).

Perl scripts on NC and SC have changed slightly to output the libvirt xml rather than the iscsi block device


### LIBRBD overview:

* C/C++/Python bindings available
* rados-java JNA bindings available from ceph git repo
* 'rbd' command-line provides shell access to librbd


# Investigations

1. What is the "best" way for using RBD? Performance and failure modes are important.
    1. Kernel module - Can use existing NC iSCSI workflow to present the block device to VM
    1. Qemu/KVM driver directly - Will require different operations to attach the device to the VM, workflow is different than for iSCSI

    
1. Performance characteristics for Ceph at small to medium scales
    1. 5 - 10 nodes, is it comparable to a SAN? IOPs and bandwidth are important
    1. Can OSDs be co-located with NCs? Seems operationally hazardous, need to establish best-practices for Euca. Expected outcome of such an investigation is that OSDs should not be run on NC hosts (this is the current Ceph recommendation for OpenStack: keep them separate[http://ceph.com/docs/next/rbd/rbd-openstack/](http://ceph.com/docs/next/rbd/rbd-openstack/))

    





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:ebs]]
