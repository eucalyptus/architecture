

| 4.1 | 
| [PRD-153 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/PRD-153)[ARCH-60 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/ARCH-60)[EUCA-9598 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9598) | 
| DRAFT | 
|  | 
| Lead designer | 
| Lead developer | 
| Lead tester | 
|  --- | 
|  --- | 
|  --- | 
|  --- | 
|  --- | 
|  --- | 
|  --- | 
| 4.1 | 
| [PRD-153 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/PRD-153)[ARCH-60 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/ARCH-60)[EUCA-9598 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9598) | 
| DRAFT | 
|  | 
| Lead designer | 
| Lead developer | 
| Lead tester | 


## Goals for 4.1

* Give Eucalyptus operators the ability to alarm their deployment so that service failure events can result in active admin notification
* Leverage Nagios to provide monitoring interface and alarming (for 4.1)
    * For each Eucalyptus service and component, provide basic health status that map to Nagios primitives
    * UP/OK, WARN, ERROR, CRITICAL
    * Hard/Soft state for each. Identify some baseline max_check_attempts numbers to transition between hard/soft states

    

    
* Provide Eucalyptus internal metrics for determining health of components to external services via an explicit interface for monitoring
* Provide clear extension points so that further monitoring data, sensors, and logic can be added in the future. Clear API and documented process for creating/adding
* Make the system not dependent on Nagios specifically, but can leverage it for reference implementation (support other systems, but not necessarily deliver the glue bits in 4.1)
* Deployment should accommodate Euca components running in VMs.
* Monitoring subsystem should behave sensibly (be quiet, use minimal resources) when Nagios is not installed or not installed correctly.
* Specification may need to define how we handle dynamic, distributed services like ELB and Imaging.
* Specification may need to consider discovery of data sources in Nagios.
* Architecture should take into account naming schemes (name spaces) used within monitoring systems to identify data sources.
* Architecture should consider integration with our fault subsystem (e.g., most FATAL transitions should be accompanied by an entry in the fault log).


## Assumptions

* Installation of Nagios itself is out of scope and exists outside of Eucalyptus
* It is acceptable for alarms to activate during maintenance done by the operator. These can be safely ignored


## Feature Requirements


| # | Title | User Story | Importance | Notes | 
|  --- |  --- |  --- |  --- |  --- | 
| 1 | Nagios NRPE call to euca-admin-get-stats | As an operator I want to connect Nagios to the output from the euca local host tools | Must Have | <ul><li>Additional considerations or noteworthy references (links, issues)</li></ul> | 
| 2 | Service state: UFS |  | Must Have |  | 
| 3 | Service state: OSG |  | Must Have |  | 
| 4 | Service state: db |  | Must Have |  | 
| 5 | Service state: sc |  | Must Have |  | 
| 6 | Service state: vmware broker |  | Must Have |  | 
| 7 | Service state: CC |  | Must Have |  | 
| 8 | Service state: CLC |  | Must Have |  | 
|  | Service state: eucanetd |  | Must Have |  | 
|  | Service state: UI |  | Must Have |  | 
|  | Configuration guide to basic Nagios NRPE calls for euca components |  | Must Have |  | 
|  | Ability to write new sensors without re-compiling Eucalyptus |  | Important |  | 
|  | Get stats over a time-range for a singe metric: euca-admin-get-stats --component cc --metric status --sample-period 60 --sample-size 10 |  | Nice to have |  | 
|  |  |  |  |  | 


## User interaction

### Local host monitoring data
Users can view monitoring data for local host components using a CLI tool.

 **NOTE: The name is just a suggestion, json also just a suggestion, any format works. Examples are made-up and don't indicate the actual sensor set committed to for 4.1** 


```
>euca-admin-get-stats --help
Usage: euca-admin-get-stats --component [ db|cluster|ufs|osg|nc|broker|net ] --metric [ service_state|msg_latency|....|all  ]
>euca-admin-get-stats --component cluster --metric service_state
{ "service": "CC_00", 
	"timestamp": "12:12:00.000UTC",
    { "status": "OK" }
}
>euca-admin-get-stats –component cluster --metric msg_latency
{ "service": "CC_00",
	"timestamp": "15:10:00.000UTC",
    { "msg_latency": {
		"period":"60s",
        "doDescribeServices: { "mean": "10ms", "median": "12ms", "quartile1":"3ms", "quartile2":"12ms", "quartile3":"17ms", "quartile4":"20ms"},
        "doDescribeInstances: { "mean": "10ms", "median": "12ms", "quartile1":"3ms", "quartile2":"12ms", "quartile3":"17ms", "quartile4":"20ms"},
        "doDescribeResources: { "mean": "10ms", "median": "12ms", "quartile1":"3ms", "quartile2":"12ms", "quartile3":"17ms", "quartile4":"20ms"}
	}
}
```
Configuring Monitoring System IntegrationNagiosNagios, or any monitoring system using a pull-model, interacts with euca monitoring via the same local cli tool available to admins.


* Add detail here
* Nagios NRPE invokes check_euca plugin that invokes euca-admin-get-stats with various parameters
* Configure NRPE for proper config


## Questions
Below is a list of questions to be addressed as a result of this requirements document:



| Question | Outcome | 
|  --- |  --- | 
| Is simple status information for each component sufficient for 4.1? | Yes, MVP is service status for each service in Euca | 
| Is there an immediate need for push-model support? | No. Initial implementation is Nagios NRPE which is pull-based | 


## References

* Nagios States:[http://nagios.sourceforge.net/docs/3_0/statetypes.html](http://nagios.sourceforge.net/docs/3_0/statetypes.html)
* Nagios NRPE:[http://nagios.sourceforge.net/docs/nrpe/NRPE.pdf](http://nagios.sourceforge.net/docs/nrpe/NRPE.pdf)




## Not Doing

* Out of scope for 4.1 is full instrumentation of a Eucalyptus deployment. We will not get all the sensors and metrics that we know would be useful in this release

    
    * Message Q length
    * Request latencies
    * Message delivery failures
    * Some JVM properties (heap space, threads, etc)

    
* Not delivering an auto deployment system for Nagios
* VMware infrastructure is out of scope. Broker is in scope, but not ESX(i).
* Not doing user API operations or audit logs.



*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:monitoring]]
