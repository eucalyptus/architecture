Architectural Discovery Checklist

 ================================= 

[https://github.com/eucalyptus/architecture/wiki/dns-3.4-spec](https://github.com/eucalyptus/architecture/wiki/dns-3.4-spec)



== DNS 4.0 Notes ==

 1. Update bucket and ELB DNS.

 2. Fix/Centralize configuration of DNS.

 -- Instance subdomain configured at CLC, must send to CC, used as

 'searcdomain' in resolv.conf

 -- Internal Eucalyptus instance DNS must send to CC and needs to be

 first 'nameserver' in resolv.conf (used for, instance-data, split

 horizon, etc resolvers)

 -- Additional DNS servers need to be @Configurable: move from being

 configured on CC in eucalyptus.conf. Should have a global default and

 also cluster specific configuration. Must send to CC for use as

 additional 'nameserver' entries in resolv.conf

 -- Add @Configurable for the nameserver that Eucalytpus should use

 when doing recursive resolution; done through

[http://www.xbill.org/dnsjava/doc/org/xbill/DNS/ResolverConfig.html](http://www.xbill.org/dnsjava/doc/org/xbill/DNS/ResolverConfig.html)

 -- Standardize per-service DNS subdomains and their configuration,

 too. e.g., the way instance, ELB, bucket DNS subdomains are set.

 3. Fixes to DNS server implementation (e.g. see attachment with comments there)

 4. Define standard configuration for (e.g.) bind to do DNS zone delegation

 5. IMPORTANT: Test plan for DNS functionality:

 -- bind delegation setup

 -- service-specific DNS (ELB, S3, EC2)

 -- split-horizon DNS

 -- system-service DNS

 -- various system deployment topologies (co-located CLC/CC, all

 remote, multi-cluster, etc)

 -- also test w/o bind delegation setup?

 6. Identify methodology for pushing DNS data to external servers

 (e.g., using AXFR, nsupdate, denominator, similar)

 7. As time/need allows add support for pushed to external DNS

 8. Do Route53 service with above pieces



 == JIRA Survey ==

 \[1] [https://eucalyptus.atlassian.net/browse/EUCA-6079](https://eucalyptus.atlassian.net/browse/EUCA-6079)

 - This ticket should be superceded by this work and either closed now

 or upon completion.



 \[2] [https://eucalyptus.atlassian.net/browse/EUCA-7917?focusedCommentId=57403](https://eucalyptus.atlassian.net/browse/EUCA-7917?focusedCommentId=57403)

 \[3] [https://eucalyptus.atlassian.net/browse/EUCA-7816](https://eucalyptus.atlassian.net/browse/EUCA-7816)

 - the comment in \[2] addresses the bug also referenced in \[3] which

 calls out the indicated fix.



 \[4] [https://eucalyptus.atlassian.net/browse/EUCA-7758](https://eucalyptus.atlassian.net/browse/EUCA-7758) and

[https://eucalyptus.atlassian.net/browse/EUCA-4206](https://eucalyptus.atlassian.net/browse/EUCA-4206)

 - we should be binding to the any-address, see the attached script and

 its comments.



 \[5] [https://eucalyptus.atlassian.net/browse/EUCA-7789](https://eucalyptus.atlassian.net/browse/EUCA-7789)

 - the 3.4 DNS nameserver names are [ns1.subdomain.com](http://ns1.subdomain.com) and resolve to

 the host address: resolved.



 \[6] [https://eucalyptus.atlassian.net/browse/EUCA-7656](https://eucalyptus.atlassian.net/browse/EUCA-7656)

 - This is a bug in the RequestType.NS clause of

 com.eucalyptus.util.dns.

NameserverResolver.lookupRecords(Record)



 \[7] [https://eucalyptus.atlassian.net/browse/EUCA-7657](https://eucalyptus.atlassian.net/browse/EUCA-7657)

 - Support for ANY queries needs to be added



 \[8] [https://eucalyptus.atlassian.net/browse/EUCA-7655](https://eucalyptus.atlassian.net/browse/EUCA-7655)

 - Support for SOA queries needs to be added



 \[9] [https://eucalyptus.atlassian.net/browse/EUCA-7349](https://eucalyptus.atlassian.net/browse/EUCA-7349)

 \[10] [https://eucalyptus.atlassian.net/browse/EUCA-7814](https://eucalyptus.atlassian.net/browse/EUCA-7814)

 \[11] [https://eucalyptus.atlassian.net/browse/EUCA-6364](https://eucalyptus.atlassian.net/browse/EUCA-6364)

 \[12] [https://eucalyptus.atlassian.net/browse/EUCA-2735](https://eucalyptus.atlassian.net/browse/EUCA-2735)

 \[13] [https://eucalyptus.atlassian.net/browse/EUCA-1659](https://eucalyptus.atlassian.net/browse/EUCA-1659)

 \[14] [https://eucalyptus.atlassian.net/browse/EUCA-2153](https://eucalyptus.atlassian.net/browse/EUCA-2153)

 \[15] [https://eucalyptus.atlassian.net/browse/EUCA-7963](https://eucalyptus.atlassian.net/browse/EUCA-7963)

 - Configuration related bugs.



 \[16] [https://eucalyptus.atlassian.net/browse/EUCA-4206](https://eucalyptus.atlassian.net/browse/EUCA-4206)

 - A bug related to topology and candidate for testing



 \[17] [https://eucalyptus.atlassian.net/browse/EUCA-1410](https://eucalyptus.atlassian.net/browse/EUCA-1410)

 - Request for push DNS



 \[18] [https://eucalyptus.atlassian.net/browse/EUCA-6429](https://eucalyptus.atlassian.net/browse/EUCA-6429)

 \[19] [https://eucalyptus.atlassian.net/browse/EUCA-6427](https://eucalyptus.atlassian.net/browse/EUCA-6427)

 - TCP server bugs to fix along the lines of UDP server bugs







 Dependencies


* Features (external to this feature)

DNS servers & clients


* Existing
* In Progress
* Missing
* Software
* Libraries
* Services (external) 

    

     Interfaces
* APIs
* Clients
* Configuration
* Formats
* Authentication
* Signatures
* Logs
* Persistence
* Databases
* Filesystems
* Services
* Administrative
* SOAP / Query / REST APIs 

    

     Errors
* Conditions
* Functional Degradation
* States 

    

     Security
* Authentication and access control
* Users
* Services
* Data
* At Rest
* In Flight
* Processing
* Network and message security
* External Services 

    

     Delivery
* Deliverables
* Distribution
* Packaging 

    

     Development
* Build
* Expertise
* Language 

    

     Resources
* Hardware
* Availability
* Configuration
* Software
* Teams 

    

     Risks
* Areas of greater than usual complexity
* Unknowns 

    

     References
* Specifications (external)





*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:dns]]
