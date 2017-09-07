

* [Description](#description)
* [Tracking](#tracking)
  * [Related Features](#related-features)
* [Analysis](#analysis)
  * [Identity, Permissions, Resources and Credentials](#identity,-permissions,-resources-and-credentials)
  * [AWS ](#aws-)
  * [AWS Console Federated Login Support](#aws-console-federated-login-support)
  * [Account Provisioning](#account-provisioning)
  * [Globus Auth Authorization](#globus-auth-authorization)
  * [Identity Mapping](#identity-mapping)
    * [No Mapping](#no-mapping)
    * [Contextual Mapping](#contextual-mapping)
    * [Console Mapping](#console-mapping)
    * [Globus Mapping](#globus-mapping)
    * [Account Alias Mapping](#account-alias-mapping)
  * [Region Federation](#region-federation)
  * [Service APIs](#service-apis)
* [Use Cases](#use-cases)
  * [Admin Use Cases](#admin-use-cases)
    * [Initial Setup](#initial-setup)
    * [Account Setup](#account-setup)
    * [Account Teardown](#account-teardown)
  * [User Use Cases](#user-use-cases)
    * [Use Account via Console](#use-account-via-console)
    * [Use Account via Portal](#use-account-via-portal)
  * [Assumptions and Questions](#assumptions-and-questions)
* [Elements](#elements)
  * [Client](#client)
  * [Console](#console)
  * [OpenID Connect Provider](#openid-connect-provider)
  * [STS](#sts)
  * [IAM](#iam)
  * [EC2](#ec2)
* [Interactions](#interactions)
  * [STS Assume Role](#sts-assume-role)
  * [EC2 Service Use](#ec2-service-use)
* [Abstractions](#abstractions)
  * [OpenID Connect Provider](#openid-connect-provider)
* [Milestones](#milestones)
  * [Sprint 1](#sprint-1)
  * [Sprint X](#sprint-x)
* [Risks](#risks)
* [References](#references)



# Description
Support login to the console using Globus Auth OpenID Connect (oidc)


# Tracking

* Status: Step #1, initial draft


## Related Features
Features in the 5.0 release that are relevant for this feature.


* [[Account and User Resource Management|Account-and-User-Resource-Management]] : for account cleanup
* [[Managed Policies|Managed-Policies]] : could simplify policy management for roles in different accounts


# Analysis

## Identity, Permissions, Resources and Credentials
Federated users do not have the unique identifier or metadata that regular IAM users are associated with. To identify a federated user the ARN can be used. The permissions for a federated user are determined from a base role or user plus any further restrictions from policies supplied at credential creation time.

The resourcesaccessible to a federated user are those in the account that the user belongs to. The permissions for the user can further restrict the accessible resources.

If a federated user is permitted to create additional users and associated policies/credentials then they can access all resources in the account including those created by other federated users. If federated users have full account access then they could remove any account configuration related to web identity federation (for example)


## AWS OpenID Connect Support
AWS supports accessing role credentials for an oidc identity using the following steps:


1. Configure an application with the oidc provider
1. In IAM create an oidc provider
1. In IAM create a role to be assumed
1. In IAM configure the policy for the role

A user can then access AWS by:


1. Getting token from the oidc provider for the application
1. In STS calling AssumeRoleWithWebIdentity
1. Accessing a permitted AWS service using the obtained credentials

During policy evaluation AWS support additional IAM condtion keys related to oidc principals.


## AWS Console Federated Login Support
The AWS console supports a federation endpoint:

https://signin.aws.amazon.com/federation

which allows the actions:


* 
```
getSigninToken
```

* login

The sign in token action exchanges temporary security credentials for a token.

The login action performs the login and accepts additional parameters to specify the destination page (page shown when logged in) and to specify the URL to redirect the user to on credential expiration.


## Account Provisioning
Accounts in the cloud would need to be either created in advance or on first use.


## Globus Auth Authorization
Web applications can be configured to allow login via Globus Auth. An application would be registered and would receive credentials to use for interactions.

The OAuth 2.0 and OpenID Connect specification are followed to perform authorization and subsequently access identity information sufficient for use with the AWS STS AssumeRoleWithWebIdentity action.


## Identity Mapping
Identities must be mapped between oidc / globus identity and a cloud account (or more accurately a role ARN)

Configuration of OpenID Connect identity providers would either be performed per target account or globus auth would be added as a recognized provider for the cloud (as are some providers with aws/iam)

The target account would be identified to the STS service by the role ARN specified in the AssumeRoleWithWebIdentity request.


### No Mapping
In this case there is no identity mapping, all oidc identities map to a single account. Using a single account means resources of one identity could be visible to other identities, quotas could not be used to control resource usage by identities, etc.


### Contextual Mapping
The account information is provided to the console, possibly by the user entering an account number when logging in.


### Console Mapping
The console stores mappings between oidc identities and accounts. Mappings would be configured as part of account provisioning.


### Globus Mapping
The account or role arn is included in information from globus.


### Account Alias Mapping
The account alias is configured to match some information from globus, allowing the console to construct the appropriate role ARN. This requires use of non-standard role arns.


## Region Federation
Existing console region federation support would allow access to multiple regions.


## Service APIs
The following summarizes the API actions we would need to support:



| Service | Action | Comments | 
|  --- |  --- |  --- | 
| IAM | AddClientIdToOpenIDConnectProvider |  | 
| IAM | CreateOpenIDConnectProvider |  | 
| IAM | DeleteOpenIDConnectProvider |  | 
| IAM | GetOpenIDConnectProvider |  | 
| IAM | ListOpenIDConnectProviders |  | 
| IAM | RemoveClientIDFromOpenIdConnectProvider |  | 
| IAM | UpdateOpenIDConnectProviderThumbprint |  | 
| STS | AssumeRoleWithWebIdentity | Except  **Policy**  and  **ProviderId**  request parameters | 




# Use Cases

## Admin Use Cases

### Initial Setup
An administrator configures external systems (globus) for use with eucalyptus, e.g.


* OAuth 2.0 client registration - for client identifier and confidential client credentials


### Account Setup
An administrator creates an account and configures it for federated use, e.g:


* Create an account
* Create an identity provider in the account
* Create a role in the count for use with the identity provider / registered client


### Account Teardown
An administrator removes an account, e.g.


* Delete role and identity provider
* Terminate / delete any resources in use
* Delete the account


## User Use Cases

### Use Account via Console
A federated identity accesses an account, e.g.


* Logs in to console using federated identity / credentials


### Use Account via Portal
A federated identity accesses cloud via portal, e.g.


* User authenticated (\w globus) on third-party site accesses link to console
* Console transparently authorizes user and goes to post-login screen


## Assumptions and Questions
Assumptions and open questions around requirements for the feature.

Assumptions:


* we do not need to support additional policy when assuming role

Open questions:


* What are requirements for "portal" use case?
* API access requirements for federated users
* Mapping between globus and eucalyptus identities
* Are resource usage restrictions required? (e.g. quotas), per-user restrictions will not work for federated users


# Elements
![](images/architecture/oauth2_elements.png)


## Client
An external client, accessing the console using a web identity.


## Console
The console, allowing login using a web identity.


## OpenID Connect Provider
An external identity provider.


## STS
The  _TokensService_ , allowing a role to be assumed using a web identity.


## IAM
The  _EuareService_  providing metadata for OIDC providers.


## EC2
A service allowing access using temporary credentials such as a role assumed via a web identity.


# Interactions

## STS Assume Role
An unauthenticated client passes an OpenID Connect ID token to assume a role. The  _TokensService_ performs discovery for the OpenID Connect provider using provider metadata from IAM for trust. The discovered provider metadata is used to verify the OpenID Connect ID token and the roles policy is used for authorization. If other checks (e.g. expiry) pass then credentials are returned to the client.


## EC2 Service Use
Temporary credentials from an assumed role are used to access the  _ComputeService._  STS authenticates the temporary credentials and IAM provides the policy for the client to be authorized.


# Abstractions
JSON Web KeyA signing key obtained via OpenID Connect discovery used to verify a signed JSON Web Token such as an OpenID Connect id token.

OpenID Connect ID TokenA JSON Web Token instance suitable for assuming a role via STS. 


## OpenID Connect Provider
Persistent metadata for an OIDC provider created in IAM for an account.

Identifies a third-party provider and has properties defining trust for discovery (thumbprint) and assuming roles (client ids)


# Milestones

## Sprint 1
Functionality target for sprint 1 is:


* IAM functionality implemented for managed of OpenID Connect providers
* Proof of concept implementation of STS assume role with web identity
* Proof of concept implementation of console log in with globus


## Sprint X
Functionality with no current target is:


* STS assume role with web identity full implementation
* Console log in with globus complete
* Console log in with globus portal use case
* Multiple region support (region federation)
* Support for federation specific IAM policy keys (outside of STS)
* Euca2ools support for new IAM actions


# Risks
Areas currently identified as risks:


* Mapping of identities between globus and eucalyptus
* Possible requirement of global provider configuration (so not per-account which we will initially support)


# References

* 5.0 [[feature details|OAuth-2.0-Support]]
* 5.0 epic (TODO)
* [OpenID Connect (openid.net)](http://openid.net/connect/)
* [Globus Auth Introduction (docs.globus.org)](https://docs.globus.org/api/auth/introduction/)
* [Globus Auth API Reference : Verifying identity via OpenID Connect ID Token (docs.globus.org)](https://docs.globus.org/api/auth/reference/#verifying_identity_via_openid_connect_id_token)
* [RFC-6749 : The OAuth 2.0 Authorization Framework (tools.ietf.org)](http://tools.ietf.org/html/rfc6749)
* [IAM UG : IAM Identifiers / ARNs (docs.aws.amazon.com)](http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns)
* [IAM UG : Creating a URL that Enables Federated Users to Access the AWS Management Console (docs.aws.amazon.com)](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html)
* [IAM API : CreateOpenIDConnectProvider (docs.aws.amazon.com)](http://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateOpenIDConnectProvider.html)
* [IAM UG : Creating a Role for Web Identity or OpenID Connect Federation (docs.aws.amazon.com)](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)
* [IAM UG : Creating OpenID Connect (OIDC) Identity Providers (docs.aws.amazon.com)](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
* [IAM UG : Available Keys for Web Identity Federation (docs.aws.amazon.com)](http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html#condition-keys-wif)
* [STS API : AssumeRoleWithWebIdentity (docs.aws.amazon.com)](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)





*****

[[tag:confluence]]
[[tag:rls-4.4]]
[[tag:federation]]
