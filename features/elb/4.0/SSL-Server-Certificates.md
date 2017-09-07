


# Overview


\[1] User puts cert and private key (PK) into IAM

 -- IAM encrypts the USERPK and stores it

 -- user gets back the ARN; call it USERPKARN

\[2] User creates ELB w/ listener that references cert/pk called USERPKARN as SSLCertificateId; to use USERPK

  -- ELB doesn't have the USERPK just the USERPKARN for it



Now, ELB needs to launch the LBVM and IAM /somehow/ grants that LBVM access to the private key and certificate identified by the USERPKARN.


# Requirements


This solution has the following characteristics:- NODEPK is the weakest link when NODECERT is used for encrypting the LBPK to put into the run instance

- NC has to be able to interact w/ userdata to extract the LBPK-encrypted(NODECERT)

 - User data could perhaps be replaced by modifiable instance attributes (which still carries the above cost, but would allow for renewal of the LBVM identity by updating the magic LBPK-encrypted(NODECERT) attribute)

- No service has to change behaviourally, esp. wrt. tracking intermediate state:

  - ELB doesn't need LBVM state

 - IAM doesn't track trusted tokens

 - EC2 doesn't do anything special at all

- All the key generation, encryption, decryption, signing and verification steps are common code already

 - LBVM uses cryptographic identity (LBCERT) specific to the LBVM and the IAMPK

- The signed LBCERT has a valid time period by definition

- If the server cert/pk change(USERPKARN) then:

 - LBVM can detect that through meta-data

  - If LBCERT is still valid, then LBVM can obtain the new USERPK

 - Otherwise, LBVM self-destructs and is replaced 

 - LBVM can run arbitrarily long w/o additional risk

 - LBVM obtains corresponding private key w/o static configuration or preconfiguration

Security
* USERPK should be protected from unauthorized access (CRUD) at rest and in flight
* access to a particular USERPK should only be granted to LBVM(s) that were authorized to use it by a user through the ELB configuration(all other running LBVMs should not be able to get access to USERPK)


# Analysis / Spike Results
Summary of earlier analysis regarding SSL support


# Specification

###  AWS APIs
IAM Server Certificates


###  Model / Components
 Component APIsEUARE Internal operation for securely getting the private key and certificate.



 Service Interactions1. ELB does:

  - instructs EUCALYPTUS that LBCERT/LBPK should be created (i.e., secure delivery of server cert is required to the VM).

  - use special keyword inserted into user-data to instruct EUCALPTUS (if needed other services such as imaging service can use this routine).



2. EUCALYPTUS does:

  - creates keypair (not ssh; regular RSA) for LBVM

 - call it LBCERT and LBPK

 - sends IAM LBCERT (i.e., signCeritificate api)



3. IAM takes those and:

 - sign LBCERT with IAMPK

 - returns LBCERT-signed(IAMPK) and IAMCERT



4. EUCALYPTUS then:

 - uses NODECERT to encrypt LBPK giving LBPK-encrypted(NODECERT)

  - uses NODECERT to encrypt LBCERT-signed(IAMPK)  (because this is confidential token that authorizes access to server cert)

  - sends run instance to CC with credentials field containing:

  - LBCERT-signed(IAMPK)-encrypted(NODECERT)

  - LBPK-encrypted(NODECERT)

   - IAMCERT



5. NODE receives run instance:

 - finds and parses out credentials field

 - extracts and decrypts LBPK-encrypted(NODECERT) and LBCERT-signed(IAMPK)-encrypted(NODECERT) using NODEPK

 - now has LBPK/LBCERT-signed(IAMPK), IAMCERT and puts them into floppy for LBVM

 - boots LBVM with the floppy



6. User assigns USERPKARN to an ELB:

  - ELB role for the affected LB is updated to only grant access to the USERPKARN



7. LBVM is notified the USERPKARN:

  - uses floppy to obtain LBPK, LBCERT-signed(IAMPK), IAMCERT

 - uses IAM role credentials

 - sends IAM request (downloadServerCeritificate) for the USER cert and private key with:

  - USERPKARN identifying the cert/private key

  - LBCERT-signed(IAMPK) in plaintext

 - Timestamp

 - Signature of USERPKARN+Timestamp using LBPK: USERPKARN+Timestamp-signed(LBPK)



8. IAM gets request and:

  - IAM authorizes access to USERPKARN given the LB's role

  - verifies signature of LBCERT-signed(IAMPK)

    - With IAM role authorization and signing with IAMPK, confirms creator had access to USERPK

    - no one tampered with the LBCERT

 - loads the USERPK-encrypted(IAMCERT) identified by USERPKARN

 - decrypts the USERPK using the IAMPK

 - using LBCERT-signed(IAMPK):

  - verifies signature of USERPKARN+Timestamp-signed(LBPK)

  - confirms it was signed using LBPK

  - the signature originates from the owner of LBPK

   - request did not expire



9. IAM prepares the response:

 - encrypts USERPK using LBCERT-signed(USERPK)

    - now requires LBPK to decrypt

  - generates signatureUSERPKARN using IAMPK:USERPKARN-signed(IAMPK)

  - returns USERCERT, USERPK-encrypted(LBCERT-signed(IAMPK)) andUSERPKARN-signed(IAMPK)



10. LBVM then:

  - verifiesUSERPKARN-signed(IAMPK) using IAMCERT (from floppy)

  - has USERCERT from IAM

 - has LBPK from the floppy earlier

 - decrypts USERPK-encrypted(LBCERT-signed(IAMPK)) using LBPK

 - gets back USERPK

 - uses USERPK and USERCERT as needed



 Feature Details More detailed breakdown of the feature with subsections for any items

 of note.



 Client Tools Description of client tool functionality changes for this feature.



 Administration Administrative and operational functionality for the feature (could be

 broken down into personas). Limits/quotas could be described in this

 section also.



 Upgrade (Security, Packaging, Documentation) Other sections as necessary to detail specifications fornon-functional attributes. Packaging section could detail the expectedpackaging changes (new libraries, new dependencies or scripts, etc)

Design Constraints / Considerations
* names of server certificates must be alphanumeric, including the following common characters: plus (+), equal (=), comma (,), period (.), at (@), and dash (-)\[AWS[limitations](http://docs.aws.amazon.com/IAM/latest/UserGuide/LimitationsOnEntities.html)]



Any other input to the design process from an architectural level. This

section could include constraints around future enhancements to the

feature.




### Testing / QA



# NOTES
Your point is right. As the user may not have uploaded the certificate/private key yet -- but already defined the ELB; launching the LBVM -- we cannot rely on the USERPK's existence. 



Per our conversation today, an alternative which does not compromise the overall characteristics of the protocol would be to use the IAMPK instead. This would still ensure that the IAM service has explicitly authn that LBVM (through its LBVCERT-signed(IAMPK)).However, a consequence is that the relationship with the USERPK is lost and, unless additional access control is enforced, any authenticated LBVM can access any USERPK. This is something that I think we can address through authz using IAM policies. For that to work two assumptions I'm making would have to hold:1. ELB service uses a separate role for each ELB and hence one per the collection of LBVMs for a user-defined ELB. A cursory look suggests this might not be the case \[1], but also seems easy enough to remedy: 

 - s/DEFAULT_ROLE_NAME/evt.getContext().getAccountNumber()+"/"+evt.getLoadbalancerName()/- Similar change when the ELB is deleted



2. The set of policies associated with the ELB role are updated to only grant access to the USERPK when the ARN is know. That is, only after the LoadBalancerListener with a valid SSLCertificateId is set.I have not pursued #2 at all and cannot speak to #1 beyond these observations.





*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:elb]]
