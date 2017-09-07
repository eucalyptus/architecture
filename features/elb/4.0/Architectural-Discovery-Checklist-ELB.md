Architectural Discovery Checklist : ELB

 Epic : [PRD-147](https://eucalyptus.atlassian.net/browse/PRD-147) Stories : PRD-91, PRD-92

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


* Session stickiness


* HAProxy - the support for app-defined cookie and the app-agonistic cookies. Run-time reconfiguration of the existing LB setup (software - existing).


* SSL termination


* HAProxy - the support for SSL (software - existing).
* IAM server certificate (missing) 

    

     Interfaces
* APIs


* ELB apis related to policy (required for session stickiness)

     : Create/Describe/Delete LoadbalancerPolicies, DescribeLoadBalancerPolicyType,
* ELB apis related to session stickiness

     : CreateAppCookieStickinessPolicy, CreateLBCookieStickinessPolicy
* ELB apis related to ssl termination

     : SetLoadBalancerListenerSSLCertificate


* Clients


* Euca2ools (eulb-\*)
* User Console (ELB support planned for 4.0 ?)


* Configuration


* Additional configuration may be needed for ssl termination (use of server certificates)


* Administrative


* Additional installation steps may be needed for ssl termination (to bootstrap trust chain) 

     Security


* Related notes can be found \[1].
* Distribution of the private SSL key to VMs:
    * authentication of the VM receiving the key
    * authentication of the key sender
    * secrecy of the key at rest and in transit

    

    Delivery

    
* Deliverables


* Service implementation (code and package)
* Haproxy servo scripts (code and package)
* Documentation and example code 

     Development


* Build


* Java build
* Servo image build (jenkins)


* Expertise


* Be able to understand and configure HAProxy


* Language


* JAVA and Python 

     Resources


* Teams


* Developer, packaging (for Haproxy Servo), and QA 

     Risks


* Areas of greater than usual complexity


* IAM server certificates (dependency)


* implementation of API (with security enforced)
* need to deliver user's credentials to HAproxy securely 

     References
* Specifications (external) 

     \[1] [{+}](https://github.com/eucalyptus/architecture/blob/master/features/iam/3.3/server-certs-spec.wiki)[https://github.com/eucalyptus/architecture/blob/master/features/iam/3.3/server-certs-spec.wiki+](https://github.com/eucalyptus/architecture/blob/master/features/iam/3.3/server-certs-spec.wiki+)

     \[2] IAM server certificates: [{+}](http://docs.aws.amazon.com/IAM/latest/UserGuide/InstallCert.html)[http://docs.aws.amazon.com/IAM/latest/UserGuide/InstallCert.html+](http://docs.aws.amazon.com/IAM/latest/UserGuide/InstallCert.html+)

     \[3] ELB session stickiness: [{+}](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/US_StickySessions.html#us-enable-sticky-api)[http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/US_StickySessions.html#us-enable-sticky-api+](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/US_StickySessions.html#us-enable-sticky-api+)



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:elb]]
