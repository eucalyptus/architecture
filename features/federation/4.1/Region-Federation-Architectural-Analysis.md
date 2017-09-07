 **Region Federation** [PRD-219 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/PRD-219)

[ARCH-67 JIRA (eucalyptus.atlassian.net)](https://eucalyptus.atlassian.net/browse/ARCH-67)

  * [Overview & Key Characteristics](#overview-&-key-characteristics)
  * [Use Cases](#use-cases)
  * [Admin Use Cases](#admin-use-cases)
  * [User Use Cases](#user-use-cases)
  * [Elements & Interactions](#elements-&-interactions)
  * [Workflows & Coordination](#workflows-&-coordination)
  * [Abstractions & Behaviours](#abstractions-&-behaviours)
  * [Architecture Skeleton](#architecture-skeleton)
  * [Distributed Workflows & APIs](#distributed-workflows-&-apis)
  * [Federation Software & Protocols ](#federation-software-&-protocols-)



## Overview & Key Characteristics

* This feature is about identity federation, not synchronization or centralization of identity, nor does it include globalized namespace (e.g., for buckets) but should be done w/ an eye towards the latter.
* There are AWS APIs supporting federation: SAML-based federation[, See SAML Providers](http://docs.aws.amazon.com/IAM/latest/UserGuide/idp-managing-identityproviders.html). Security Tokens via STS,[ See Delegation & Federation](http://docs.aws.amazon.com/IAM/latest/UserGuide/WorkingWithRoles.html).
* Identity in Eucalyptus consists of: Accounts, Users, Groups, Roles. Authentication bits are: Access Keys, Login Profiles, and Certificaties. Policies can be associated with any of the above and are evaluated as [described here](http://docs.aws.amazon.com/IAM/latest/UserGuide/AccessPolicyLanguage_EvaluationLogic.html#policy-eval-basics).
* Observation #1: The approach taken has opportunity to be foundational to supporting hybrid identity by adopting the same basic mechanisms as used by AWS.
    * Observation #1.a.: There exist a number of candidates for providing implementations of SAML2, OAuth2, and OpenID support which are mature and possible to integrate.
    * Observation #1.b.: The approach of inventing a federation protocol has the downside of being inherently complicated, most likely a dead-end wrt interoperability and IDM integration, and difficult to evaluate for soundness.
    * Observation #1.c.: The existing candidates offer support for integrating other backend IDM systems and

    
* Observation #2: Federation implies authentication has a local-region (normal) and a federated-region (new, remote) path.
* Observation #3: For an identity authenticated by a federated region's identity provider, full subject information (account, user, policies) need to be delivered as part of the authentication token (as these are not synchronized).
* Observation #4: Of the parts of identity, there is a need for mutual exclusion between region assignments of access key identifiers and certificates
* Observation #5: There is no implied topology; be it mesh, hub-and-spoke, etc. The approach should identify the default, but not preclude other topologies.
* Question #1: Is the existing STS-driven transient identity the right integration point?
* Question #2: Of the candidates which exist is there one which: is functionally sufficient, suitable for integration, supports future efforts?


## Use Cases
Per PRD-219 above.



| ![](images/architecture/arch-67-use-case-admin.inc.png) | ![](images/architecture/arch-67-use-case-user-2.inc.png) | 
|  --- |  --- | 


## Admin Use Cases

* Configure Region to be Federated with another Region
    * Configure  _this_  region to  _trust another region_  for purposes of authentication (establish trusted provider relationship)
    * Configure  _this_ region to  _allow another region_  to use it for purposes of authentication (establish relying party relationship)

    
* Delete Region's federation relationship with another region

    
    * Delete this region's trust provider relationship with another region
    * Delete this region's relying party relationship with another region

    
* Describe Regions (with Federation information)
    * Status, Credentials establishing trust

    


## User Use Cases

* User is trying to perform  _SomeOperation_ (any operation) against
    * First, an initial region (lets say it is the region of record for the user's identity)
    * Second, another region which is federated with the initial region

    




## Elements & Interactions


| <ul><li>TODO</li></ul> | ![](images/architecture/elements.png) | 
|  --- |  --- | 






## Workflows & Coordination


| <ul><li>Federation Configuration & Management</li><li>Authentication</li><li>Account/User/Policy Management </li></ul> | ![](images/architecture/workflows.png) | 
|  --- |  --- | 






## Abstractions & Behaviours
TODO


## Architecture Skeleton


|  | ![](images/architecture/skeleton.png) | 
|  --- |  --- | 






## Distributed Workflows & APIs
TODO




## Federation Software & Protocols 

* Federation Standards, Protocols, and References
    * SAML2:
    * System for Cross-domain Identity Management: [http://www.gluu.org/resources/documents/standards/scim/](http://www.gluu.org/resources/documents/standards/scim/)
    * OAuth2
    * OpenID
    * IETF PKIX OCSP [http://tools.ietf.org/html/rfc2560](http://tools.ietf.org/html/rfc2560)

    
* Federated Identity Providers, Service Providers, and Proxies
    * Gluu/OX [https://github.com/GluuFederation/install](https://github.com/GluuFederation/install)
    * Shibboleth [https://wiki.shibboleth.net/confluence/display/SHIB2/UnderstandingShibboleth](https://wiki.shibboleth.net/confluence/display/SHIB2/UnderstandingShibboleth)
    * OpenAM [forgerock.com/openam.html](http://forgerock.com/openam.html)
    * Asimba [http://www.asimba.org/site/](http://www.asimba.org/site/)



    
* AWS Federation


    * [SAML Providers](http://docs.aws.amazon.com/IAM/latest/UserGuide/idp-managing-identityproviders.html)


    * [Delegation & Federation](http://docs.aws.amazon.com/IAM/latest/UserGuide/WorkingWithRoles.html)



    



*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:federation]]
