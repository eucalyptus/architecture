
## Overview
The  _eucalyptus-cloud_ service is restarted during development when deploying updated software (services). The service is perceived as slow to restart so we should examine performance and make improvements accordingly.

The arbitrary startup time target is 20 seconds.


## Analysis

### Topologies
The primary concern is speed of service restart during development. The main focus should therefore be the topologies that are most commonly used for development.


### Cloud resources
Performance issues due to resources allocated for services (e.g. EC2 instances) can be ignored as the main focus is development speed and such clouds will likely not have many resources.


### Service restart measurements
On a cloud with (UFS)-(CLC WS)-(SC CC)-(NC) topology times from service start to all services being reported as enabled were:



| Host components | Core time | Time (Minutes) | Notes | 
|  --- |  --- |  --- |  --- | 
| UFS | 50s | 4 | delay appeared to be due to startup of services with dependencies | 
| CLC WS | 1 | 1.5 |  | 
| SC CC | 1 | 1.5 |  | 

Core time reflects that startup prior to services.


### Startup time log
Log extract showing where time is spent during startup (CLC):




```text
Mon Nov 16 13:14:11 2015  Populating binding cache.
Mon Nov 16 13:14:32 2015  Bootstrap stage completed: UnprivilegedConfiguration
Mon Nov 16 13:14:32 2015  Bootstrap stage completed: SystemCredentialsInit
Mon Nov 16 13:14:33 2015  Bootstrap stage completed: RemoteConfiguration
Mon Nov 16 13:14:36 2015  Bootstrap stage completed: DatabaseInit
Mon Nov 16 13:14:51 2015  Bootstrap stage completed: UpgradeDatabase
Mon Nov 16 13:14:51 2015  Bootstrap stage completed: PoolInit
Mon Nov 16 13:15:16 2015  Bootstrap stage completed: PersistenceInit
Mon Nov 16 13:15:17 2015  Bootstrap stage completed: RemoteDbPoolInit
Mon Nov 16 13:15:17 2015  Bootstrap stage completed: SystemAccountsInit
Mon Nov 16 13:15:18 2015  Bootstrap stage completed: RemoteServicesInit
Mon Nov 16 13:15:18 2015  Bootstrap stage completed: UserCredentialsInit
Mon Nov 16 13:15:18 2015  Bootstrap stage completed: CloudServiceInit
Mon Nov 16 13:15:18 2015  Bootstrap stage completed: Final
```

### Startup for selected components
Some components are expected to be problematic in terms of startup performance, these components were examined for issues.



| Component | Stage | Time (seconds) | Reason | 
|  --- |  --- |  --- |  --- | 
| Mule |  _Final_ (concurrent) | 30 | Mule initialization includes spring/DI overhead | 
| Message binding generator | 
```
 _UnprivilegedConfiguration_  (pre)
```
 | 45 (+5\*) | Relevant on initial startup and when redeploying code with updated messages | 

 _*_ binding generation takes 5 seconds when there is no work to do.


### Service shutdown performance
For service restart we should also consider shutdown performance. Initial testing showed relatively good performance on shutdown when compared to service startup times.


## Candidate solutions
The most significant time is currently spent starting services that depend on the availability of other services, this should be the initial focus.

Other areas requiring startup improvement are:


* up to and including the  _UnprivilegedConfiguration_  stage
* the  _UpgradeDatabase_  stage (when not upgrading)
* the  _PersistenceInit_ stage


## References

* [Increase Topology worker pool, use EXTERNAL for manyToOne (EUCA-10946)](https://eucalyptus.atlassian.net/browse/EUCA-10946)



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:configuration]]
