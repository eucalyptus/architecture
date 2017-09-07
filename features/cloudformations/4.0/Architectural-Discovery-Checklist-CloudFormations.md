 **CloudFormations (ARCH-12/PRD-93)** Cloudformations is an AWS resource deployment management service, that allows several AWS resources to be deployed together as a logical unit (called a "stack"). This allows for complete application setup with a small XML file. Stacks are defined in "template" XML files. Operations for Cloudformations are as follows:


* create-stack – Creates a new stack (Create all the resources defined within the stack) – requires a template XML file as an argument.
* delete-stack – Deletes a stack (Delete all the resources defined within a stack)
* update-stack – Updates an existing stack (creates newly needed resources and deletes resources no longer required) – requires a template XML file as an argument.
* list-stacks – Lists all (or selected) stacks. This command can show stacks that have been deleted, and returns more results than describe-stacks
* describe-stacks – Describes all (or selected stacks).
* describe-stack-resources – Describes all resources about a given stack
* describe-stack-resource – Describes (in a bit more detail) particular resources in a given stack
* describe-stack-events – Describes events that have occurred regarding a given stack. Creating, Updating, and Deleting stacks occur in several steps, so this command shows the steps, and the times that the steps have completed.
* get-template – Returns the template XML file used to create or update the stack.
* Cancel-update-stack – Cancels a stack update in progress. Rolls back the stack to the state before update was called.
* Validate-template – Validates a template XML file. (In AWS this may actually create resources, so beware billing)

Note: The majority of Cloudformations involves the process of managing the resources within the stack. In addition, if an error occurs during any create or update process, rollback steps need to be available. A typical workflow for a cloudformations operation might be something as follows.


1. Parse the template XML file, determine which resources need to be created. \[As part of this process, resources have configuration options called "parameters" which are also defined in the XML file, some are also required to be prompted for or passed in at the command line. More info about parameters later]
1. Determine the dependency order for resources. Some resources may require other resources to already have been defined or started previously.
1. For each resource, create/start it. \[This may be done in parallel]
1. If any resource fails to be created, abort the process, and rollback all resources that have been created already. \[This requires a list of resources and their current status]
1. Update the resource status and stack status for every step on #3 and #4.

Something like the above is also probably true of delete and update stack. Allowing for some parallelization, it may be possible that something like SWF may be useful in implementing the above. In my opinion, the above is a fairly limited workflow, and might be easier to write as a standalone workflow than fully implementing something like SWF. 

 What resources are supported: The following is a list of AWS defined resources that are supported by CloudFormations, and whether or not I think they can be implemented by Eucalyptus in the current release. (4.0). 

 **Assumption: Parsing the template file, including handling "mappings", "functions" and "variables" is doable.** 

 **Assumption: Some framework for resource creation/update/rollback can be put in place.** 

 **Assumption: None of the unimplemented services in the list below will be implemented in 4.0. Even if they are implemented, hooking them into CloudFormations might take more time.** 



| Resource | Doable? | Reason | 
| AWS::AutoScaling::AutoScalingGroup | Yes | Autoscaling is supported. | 
| AWS::AutoScaling::LaunchConfiguration | Yes | Autoscaling is supported. | 
| AWS::AutoScaling::ScalingPolicy | Yes | Autoscaling is supported. | 
| AWS::AutoScaling::Trigger | No | Triggers are a deprecated feature of Autoscaling not currently supported. | 
| AWS::CloudFormation::Authentication | Yes | Looks like it is a placeholder for authentication credentials, not a first-class resource by itself | 
| AWS::CloudFormation::CustomResource | No | Requires SNS for resource notifications | 
| AWS::CloudFormation::Init | Maybe | This appears to be the items that set up applications on instances at creation. We would need special software on instances to run this or perhaps convert everything to instance metadata. | 
| AWS::CloudFormation::Stack | Yes | The basic building blocks, necessary. | 
| AWS::CloudFormation::WaitCondition | Yes | Allows some conditional control flow. | 
| AWS::CloudFormation::WaitConditionHandle | Yes | Allows some conditional control flow. | 
| AWS::CloudFront::Distribution | No | We have not implemented CloudFront | 
| AWS::CloudWatch::Alarm | Yes | Cloudwatch is supported | 
| AWS::DynamoDB::Table | No | We have not implemented DynamoDB | 
| AWS::EC2::CustomerGateway | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::DHCPOptions | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::EIP | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::EIPAssociation | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::Instance | Yes | Instances are supported | 
| AWS::EC2::InternetGateway | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::NetworkAcl | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::NetworkAclEntry | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::NetworkInterface | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::NetworkInterfaceAttachment | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::Route | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::RouteTable | Maybe | There will be some Edge Networking/VPC support in 4.0 | 
| AWS::EC2::SecurityGroup | Yes | We support security groups in EC2. | 
| AWS::EC2::SecurityGroupIngress | Yes | We support security groups and ingress rules. | 
| AWS::EC2::SecurityGroupEgress | Yes | SecurityGroupEgres is planned for 4.0 support. | 
| AWS::EC2::Subnet | Maybe | Subnets are VPC which we don't support. | 
| AWS::EC2::SubnetNetworkAclAssociation | Maybe | Subnets are VPC which we don't support. | 
| AWS::EC2::SubnetRouteTableAssociation | Maybe | Subnets are VPC, which we don't support. | 
| AWS::EC2::Volume | Yes | We support volumes in EC2 | 
| AWS::EC2::VolumeAttachment | Yes | We support attaching volumes to instances in EC2 | 
| AWS::EC2::VPC | Maybe | There will be some VPC support in 4.0 (VPC Lite) | 
| AWS::EC2::VPCDHCPOptionsAssociation | Maybe | There will be some VPC support in 4.0 (VPC Lite) | 
| AWS::EC2::VPCGatewayAttachment | Maybe | There will be some VPC support in 4.0 (VPC Lite) | 
| AWS::EC2::VPNConnection | Maybe | There will be some VPC support in 4.0 (VPC Lite) | 
| AWS::EC2::VPNConnectionRoute | Maybe | There will be some VPC support in 4.0 (VPC Lite) | 
| AWS::EC2::VPNGateway | Maybe | We do not support edge networking support in 4.0 | 
| AWS::ElastiCache::CacheCluster | No | We do not currently implement ElastiCache | 
| AWS::ElastiCache::ParameterGroup | No | We do not currently implement ElastiCache | 
| AWS::ElastiCache::SecurityGroup | No | We do not currently implement ElastiCache | 
| AWS::ElastiCache::SecurityGroupIngress | No | We do not currently implement ElastiCache | 
| AWS::ElastiCache::SubnetGroup | No | We do not currently implement ElastiCache | 
| AWS::ElasticBeanstalk::Application | No | We do not currently implement ElasticBeanstalk | 
| AWS::ElasticBeanstalk::Environment | No | We do not currently implement ElasticBeanstalk | 
| AWS::ElasticLoadBalancing::LoadBalancer | Maybe | We have implemented ELB but I don't think all of the features have been implemented (session stickiness?) so some of the parameters might not be supported. TODO: drill down into the ELB features that might be supported | 
| AWS::IAM::AccessKey | Yes | We implement IAM (as EUARE) | 
| AWS::IAM::Group | Yes | We implement IAM (as EUARE) | 
| AWS::IAM::InstanceProfile | Yes | We implement IAM (as EUARE) | 
| AWS::IAM::Policy | Yes | We implement IAM (as EUARE) | 
| AWS::IAM::Role | Yes | We implement IAM (as EUARE) | 
| AWS::IAM::User | Yes | We implement IAM (as EUARE) | 
| AWS::IAM::UserToGroupAddition | Yes | We implement IAM (as EUARE) | 
| AWS::RDS::DBInstance | No | We do not currently implement RDS | 
| AWS::RDS::DBParameterGroup | No | We do not currently implement RDS | 
| AWS::RDS::DBSubnetGroup | No | We do not currently implement RDS | 
| AWS::RDS::DBSecurityGroup | No | We do not currently implement RDS | 
| AWS::RDS::DBSecurityGroupIngress | No | We do not currently implement RDS | 
| AWS::Route53::RecordSet | No | We do not currently implement Route53 | 
| AWS::Route53::RecordSetGroup | No | We do not currently implement Route53 | 
| AWS::S3::Bucket | Maybe | We have implemented Walrus and could create buckets and their parameters, but one parameter in CloudFormations is the WebsiteConfiguration property that allows a static web site within a bucket, which is not something I think we currently support. | 
| AWS::S3::BucketPolicy | Yes | We have implemented Walrus and (presumably) policy controls | 
| AWS::SDB::Domain | No | We do not currently implement SimpleDB | 
| AWS::SNS::TopicPolicy | No | We do not currently implement SNS | 
| AWS::SNS::Topic | No | We do not currently implement SNS | 
| AWS::SQS::Queue | No | We do not currently implement SQS | 
| AWS::SQS::QueuePolicy | No | We do not currently implement SQS | 



 **Additional information** Templates consist of resources, as described above, parameters (which exist at the top level, as well as part of resources), mapping (which is essentially sets of conditional parameters, depending on key values), functions (some intrinsic, some which can be used with mappings, such as Fn::FindInMap), references (non-literal values for parameters, which are sometimes strings, sometimes numbers, sometimes complex types). Parsing and handling variables and functions, etc. is another task that needs to be done along with determining workflows.

 **Items to Research Further** How to tie in SWF to the service, the entire control flow that is required for a stack to be created, the set of states, how rollback works.

 Cloud-init, the scripts that are bundled with certain AMI's to allow configuration or installation of software.

 What parsing of xml files need to be done, especially w/rt "functions", "references", conditional values.

 The tools that one needs to use to deploy scripts. There does not appear to be a WSDL. How does Cloudformations send/receive data.

 WaitCondition and WaitConditionHandle are resources that may need to be implemented but alter control flow.

 Looking more in depth at each resource, see what other resources may be depended on.

 Research error handling and rollback.

 Much deeper dive into SWF, see what parts need to be implemented for CloudFormations.



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:cloudformations]]
