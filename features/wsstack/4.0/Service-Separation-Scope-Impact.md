
# Overview
An investigation into splitting the Eucalyptus service from the database hosts was started during 3.4 development, this investigation was not completed due to time constraints.

The goals of this investigation were:




* Separation of the Eucalyptus service to hosts without databases
* Separation of trinity services from the Eucalyptus service
* Preservation of simple setup for POC use case (co-located services)

As stated above the investigation was not completed but it is possible to determine the ballpark impact and scope.


# Impact Analysis

### Requirements
It should be possible to manually de-register trinity services if not required, but this would have to be an additional requirement on the user console if it was to be a supported feature.


### Design & Architecture
May require creation of an explicit coordinator service, or other service that can be used for user control of active database placement (manual failover)

More explicit modules for the EC2/Eucalyptus service are a natural side effect of this change. New "Compute" modules could be created and other modules removed.

Manual registration for trinity services would be necessary in an HA topology.

User console must not expect services to reside on a single host.

Administration tools require updating for registration of trinity services.


### QA System & Test Plans
There would be additional topologies to test and changes would be required for HA sequence setup (due to service registration changes)


### Packaging & Upgrade
Manual or automated update of service registrations.


### Documentation
Documentation of any new services and of service registration changes.


# Scope Assessment
Would likely require work from services and ui teams.

Scope is 1-2 sprint developers with tools / user console changes depending on services team changes.





*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:wsstack]]
