Architectural Discovery Personas / PRD-54




Dependencies


* Features
* IAM roles support (existing)
* User Console IAM / admin interfaces (in progress)


    

    
Interfaces
* Clients
* Euare commands, adding role related commands
* Euca2ools, all service authorization impacted (role discovery / use)
* User Console
* Service authorization impact
* Available operation impact
* Only display screens and operations allowed for the user's defined personae
* IAM policy editing
* Admin tools (registration of services)
* Configuration
* Role / operation definitions for Euca2ools
* Role / operation definitions for User Console
* Formats
* Policy language extension?
* Logs
* Audit trail
* Services
* All service authorization impacted
* Service authentication impact (token support)
* New service for role discovery
* IAM for internal (and euca specific, i.e. reporting) services


    

    
Delivery
* Deliverables
* Canned policies / default configurations
* Code samples


    

    
Resources
* Teams
* Services
* Tools?
* User Console


    

    
Security
* privilege separation for functionality currently available to the 'eucalyptus' account
* only a "special" super privileged user should be allowed to modify privileged roles/policies
* it should be possible to limit access to super privileged functionality (modification of privileged roles/policies and euca-modify-property script executing functionality) by an additional protection mechanism


    

    
Risks
* Support for query of the list of permissible operations (requires context / policy evaluation)
* Relation to EC2 "DryRun" / DecodeAuthorizationMessage functionality \[1]
* Performance drop for administrators due to permission evaluation


    

    
Notes
* Infrastructure / resource admins cannot delegate their responsibilities (cloud super admin must create roles)
* Assume role is per account not per user


    

    
References

    
\[1] [{+}](http://aws.typepad.com/aws/2013/07/resource-permissions-for-ec2-and-rds-resources.html)[http://aws.typepad.com/aws/2013/07/resource-permissions-for-ec2-and-rds-resources.html+](http://aws.typepad.com/aws/2013/07/resource-permissions-for-ec2-and-rds-resources.html+)

    

    
Open Issues
* Admin console functionality for personas?


    



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:iam]]
