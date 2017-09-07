
# Overview
Eucalyptus provides a systematic way to expose internal performance, health, and resource-usage metrics to external monitoring systems. The system is generic such that it depends on no specific external system, but the initial reference implementation isexpected to be Nagios NRPE support.




# Tracking
Implementation Epic:[EUCA-9598 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/EUCA-9598)

Arch Doc:[ARCH-60 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/ARCH-60)


# Constraints
The monitoring system MUST:


1. Provide extensible points to allow new measurements without recompilation for Java components
1. Support a pull-model for extracting sensor readings
1. Support parameterized ranges for quering sensor readings. E.g. period of 10 sec vs period of 1 sec
1. Support basic state values for sensors. E.g. Nagios's OK, WARNING, UNKNOWN, CRITICAL states
1. Support time-series data
1. Allow access to sensor data on the local host directly



The monitoring system MUST NOT:


1. Require a specific 3rd party monitoring system/API to extract meaningful data
1. Require Eucalyptus components to be running to return a result
1. Require compiled checks (e.g. new releases of Eucalyptus) to add sensors and metrics (C components may be exempt, at least initially)
1. Require network operations to view/retrieve data from a sensor
1. Wait indefinitely for input or output. Sensor data loss is preferable to lockup/wait


# Model Elements
Sensor
* Measures some metric over some period and returns a result
* May be internal or external to Eucalyptus processes
* Implements the sensing and pushes result to Monitoring bridge via Monitoring bridge push API

Monitoring Target
* A target host/process/metric to be monitored
* No requirement that it be java-based
* May include Euca or non-Euca process

Monitoring Bridge
* Takes monitoring data from Eucalyptus and presents it in a generically consumable form
* Expected to be accessed via a query, not push-based
* Must be light-weight
* May be lossy on failure, no persistence requirement. If persistence is needed, a client of the bridge must provide it
* Decouples the sensing/push from the gathering/pull. Must keep results around for some TTL
* Should implement little-to-no logic, just present sensor data uniformly regardless of source or consumer

Nagios Server\[2]
* The Nagios process that queries agents via NRPE

Nagios NRPE Agent\[3]\[4]
* The Nagios Remote Plugin Execution protocol to execute plugins on remote hosts without direct SSH access required.

Eucalyptus Nagios Plugin
* A Eucalyptus-specific nagios plugin that collects sensor data from the monitoring bridge and presents it to Nagios via NRPE.

Eucalyptus Monitoring Elements


# Interfaces

### SensorAPI
CLI & corresponding web API

web API - SOAP for NC/CC, REST for Java components

CLI unifies those


* statsClient <service type> <command>
    *  _e.g. statsClient sc pollsensor threadcount_ 

    


* getEvents
* getAlarms
* pollSensor(SensorName)




### Monitoring Bridge - File System
Input Interface:


* Write files with path = $EUCALYPTUS/var/run/eucalyptus/monitoring/<sensorname_path> as path where <sensorname_path> is the name of the sensor in the output with '.' replaced with '/' to make a tree
    * e.g. sensorname = euca.jvm.memory.heap.state --> $EUCALPYTUS/var/run/eucalyptus/monitoring/euca/jvm/memory/heap/state

    
* Files are not written in-place, but a temp file used an atomically renamed the proper name to ensure no reader-writer conflicts
* New sensor output always overwrites old, the output file is not a log, but a single document indicating the last-known result




```
{ 
"sensor": "<servicename/identifier>",
"timestamp": "<linux epoch-time/long>",
"ttl": "<sensor data time-to-live in seconds>",
"description": "<free-form string description>",
"tags": [ "<tag1 string>","<tag2 string>",...,"<tagn string>" ],
"values": { "<key>":"<value>", "<key2>":"<value2>", ..}
}
```
Output Interface:


* Consumers simply read the file(s) and retrieve the necessary values from the 'values' map.
* Data should be considered invalid if current time in epoch seconds >  _timestamp + ttl_ 


### Monitoring Bridge - Riemann (Not yet implemented)
Input Interface:


* Unix domain socket (local host only).
* Input: TCP/UDP with protocol buffers

Output/Query Interface:


* Unix domain socket (local host only).
* Fetch results via query of riemann index via various clients


### Sensor Design & Implementation Options

* Zorka for Java sensors. External sensor queries JVM/Euca services and pushes result into monitoring bridge
* Internal Euca Java sensors push directly to local monitoring bridge
* Eucalyptus C components have internal sensors
    * Alternate option: provide API (simple HTTP, for example) for an external sensor to pull data and dump it in the bridge

    


### Reloading and Redefining the Sensor Set Without Restarting the JVM

* It is desirable to modify the set of sensors and their properties without restarting the jvm in order to perform reconfig without service outages
* Current design is that the monitoring bootstrapper executes an external script (sensors_list.groovy) to get the set of sensor objects and schedules to execute
    * This allows entirely new sensors to be defined without a re-compile or restart of the JVM
    * Security and malicious/faulty code are concerns

    
* Possible mechanisms for triggering a reload() of the sensor set:
    * Named-pipe/fifo that the service listens on with a specific set of access controls
    * To trigger a reload, the user executes 'echo "1" > euca_cloud_monitor_reload', for example

    
    * Polling of the config file at regular intervals, any changed content of modification timestamp since last check triggers a reload
    * FS file modification notifications. The FS watches the config file and notifies the service when it is modified. No regular interval poll needed

    


## Security Considerations

1. Can anything 'secret' be presented via monitoring? No, should not ever need secrets in monitoring events. Enforcement is up to sensor implementors
1. Who has access to the Monitoring Bridge? Anyone that can open a connection to the socket. Ddos potential, should not have any functional affect on Euca services
1. Where is data persisted and how? Up to external monitoring system and deployment specific. May be ephemeral or may be persisted on disk, out of scope for this document. Assuming #1 is held true, this is not as important for security


### Filesystem monitoring data output: ensure only specific host users can read the output

1. The monitoring filesystem will be owned by 'eucalyptus' user, have group 'eucalyptus_monitoring', and have permissions: 650
1. For Nagios, or any other external system, to read the data the user for that service must be explicitly added to the 'eucalyptus_monitoring' group.
1. Eucalyptus will create the 'eucalyptus_monitoring' group by default during installation


### References

1. [Zorka](http://zorka.io) (possible jvm query tool for external sensors into JVM)
1. [Nagios](http://www.nagios.org)
1. [Nagios NRPE](http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details)
1. [NRPE Spec PDF](http://nagios.sourceforge.net/docs/nrpe/NRPE.pdf)
1. [Nagios Plugin API](http://nagios.sourceforge.net/docs/nagioscore/4/en/pluginapi.html)
1. [SNMP Spec](http://www.ietf.org/rfc/rfc2571.txt)
1. [Riemann Event Stream Processor](http://www.riemann.io) (Possible candidate for Monitoring Bridge)





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:monitoring]]
