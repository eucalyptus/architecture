
# Architectural Discovery Checklist : Admin Console
Epic  **PRD-97** : Cloud Account Admin: Graphical interface for daily operations 

 Checklist to help identify items of architectural interest with regards to feature scope. This should also help to identify areas that require investigation. 

 It is expected that most items listed are not relevant for a given feature (are not of interest at this time). The aim is only to help identify areas that are of particular interest for scoping. The list

 should not be filled out for a feature, only the parts of interest would be used.


## Dependencies

* Features (external to this feature)
    * Existing

    
* In Progress
    * We are in the process of revamping the 4.0 console architecture, and porting the existing user interfaces to the new architecture is a significant dependency.

    
* Missing
* Software
    * Libraries
    * Services (external)

    




## Interfaces

* APIs
* Client (User console)
    * Client must only display screens/options the user is allowed to perform based on permissions
    * Navigation:
    * Identity & Access Management
    * Groups
    * Users
    * Roles

    
    * Dashboard
    * New portlet for IAM with group/user/role counts

    

    
    * Policies/Permissions
    * Allow the account admin to upload a policy for user permissions and quota management.
    * An advanced GUI will allow creating a policy via policy generator (which may not be in scope for the initial 4.0 release).

    
    * Groups:
    * Create group (wizard: Group name-> perms> quotas->add/remove users)
    * Add users to group
    * Define permissions for group
    * Select predefined policies
    * Create permissions

    
    * Remove users from group
    * Delete group
    * Edit group name

    
    * Users:
    * Create user (advanced) (wizard: name(s)/generate keys option/generate PW option or enter initial PW->perms>quotas->add to/remove from groups)
    * Simple user add via template (simple) (enter names and email addys, select canned perm set, hit GO! and it auto generates everything)
    * Delete user
    * Add user to groups
    * Remove user from groups
    * Define permissions for user
    * Manage keys (create/delete)
    * Manage certs (upload) \*\*\*Is this MVP? Appears to be getting deprecated in AWS)
    * Manage password
    * Define password policy (apply sets policy for all users)

    
    * Roles:
    * Create role
    * Delete role

    
    * Configuration
    * Little to no configuration changes are expected for the 4.0 console, as the config file (console.ini file) will be very similar to the 3.4 console.

    
    * Formats
    * The user interface will be purely web-based, supporting multiple platforms and devices with a responsive, mobile-friendly web layout.

    
    * Authentication
    * Signatures

    
    * Logs
    * We're defaulting to a rotating log file handler, with the log level set to INFO for production. A sdtout log handler is also available for development, with log level DEBUG, although the handler is disabled by default.

    
    * Persistence
    * Databases
    * Not a hard dependency for 4.0 admin UI, since we're not persisting state server-side

    
    * Filesystems
    * Not a hard dependency for 4.0 admin UI

    

    
    * Services
    * Administrative
    * SOAP / Query / REST APIs

    




## Errors

* Conditions
    * Form validation will be client-side  **and**  server-side for 4.0 Console

    
* Functional Degradation
* States






## Security

* Moving form validation server-side will allow us to use the httpOnly cookie for form posts, enhancing security by helping to mitigate XSS attack vectors.
* All existing [security requirements](https://wiki.eucalyptus-systems.com/doku.php?id=sec:3.2:ui) for the user console are expected to hold




## Delivery

* Deliverables
* Distribution
    * The 4.0 console will be distributed in a similar manner as the 3.4 console, with Python packages listed as dependencies. The 4.0 console will also be published and available at PyPI (the Python package index), allowing the console to be installed via 'easy_install koala' or 'pip install koala'

    
* Packaging
    * Many new python libraries will be needed as hard dependencies.

    




## Development

* Build
* Expertise
* Language
    * Development the 4.0 Console will require experience with Python and JavaScript. This is consistent with the 3.x Console.

    




## Resources

* Hardware
    * Availability
    * No changes in hardware specs are expected for the 4.0 console

    
    * Configuration
    * Little to no configuration changes are expected for the 4.0 console, as the config file (console.ini file) will be very similar to the 3.4 console.

    

    
* Software
* Teams
    * Developers: David K., Kyo L., Kamal G. UX: Jenny L.

    




## Risks

* Areas of greater than usual complexity
* Unknowns
    * We are moving to a new Web Framework (Pyramid) and a new set of front-end frameworks (Foundation and AngularJS). Adding to the unknown are ElasticSearch and Celery/RabbitMQ.

    




## References

* Specifications (external)
    * [User Console 4.0 Architecture Revamp](https://docs.google.com/a/eucalyptus.com/document/d/1BGf8Y2MkV4X6mQz0EWSC4Jf5oFlDjQZHdduHkEYtceA/edit#heading=h.wkleogq91ysw)

    



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:user-ui]]
