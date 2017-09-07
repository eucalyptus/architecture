 **Overview** Four parts contribute to this feature:


1. Completion of the existing pull-based DNS by adding DnsResolver plugins for the remaining record types.
1. Revise the configuration scheme for the properties which govern the behaviour of the DNS server.
1. Address limitations of the current implementation which have been reported from the field.
1. Define the standard practice for deploying DNS and connecting it to the environment.
1. Develop push-based DNS for zone records which are amenable to this data model.
1. Work towards support for Route53

 **Context & Background** Background information about the state of the pull-based DNS implementation can be found in[dns-3.4-spec](https://github.com/eucalyptus/architecture/wiki/dns-3.4-spec).

Related to both implementation and test planning is the list of bugs against the current DNS.

Ultimately, push-based DNS is both in demand today and required for implementation of Route53. Work in that direction is subsequent to, but not directly dependent on, acceptance of the pull-based implementation.

 **Dependencies & Assumptions** The primary assumption here is two fold:


1. The system must service DNS requests directly for records which are based only on in-memory state. This implies continued operation of the libdnsjava based server.
1. The system must integrate with DNS at large in deployments. Delegation is the first step to formalizing support for this. Subsequently, the work towards push-based DNS will enabled more integration alternatives.

 **Requirements**  **User Stories (Functional)** 

 **Architectural Priorities & Constraints (Non-functional)** 
### Availability & Robustness
The DNS server is essential to identifying ENABLED services in the system– there is not other viable alternative today. To that end, it must be able to:


* run in an active-active configuration
* be start/stop/restart-able to support maintenance



 **Specification** 1. Update bucket and ELB DNS.

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

 **Detailed Specification**  **Code Model**  **Source Repository** Included with eucalyptus.

 **Module Organization** There are three parts to the

 **Technology Selection**  **Software** The solution is currently based on libdnsjava. In this release that may be extended to include an additional external DNS server: bind.

 **Services** Should bind be added the expectation would be that the system administrator is responsible for the service liveliness of bind.

 **Security Protocols**  **Communication Protocols** DNS for queries and zone transfers over both UDP and TCP.

 **Deployment Topologies** The internal DNS server must run on all front end hosts. The DNS server itself is active-active already. Its service lifecycle relationship will need to be updated to run on the appropriate hosts.

 **Operation & Administration**  **Internal Server**  **External Server (bind)**  **Configuration** 

 **Testing & Evaluation** Test planning for DNS functionality should address:

 -- bind delegation setup

 -- service-specific DNS (ELB, S3, EC2)

 -- split-horizon DNS

 -- system-service DNS

 -- various system deployment topologies (co-located CLC/CC, allremote, multi-cluster, etc)

 -- also test w/o bind delegation setup?

 **Packaging & Delivery** 

 **Appendix**  **JIRA Survey** \[1] [https://eucalyptus.atlassian.net/browse/EUCA-6079](https://eucalyptus.atlassian.net/browse/EUCA-6079)

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















*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:dns]]
