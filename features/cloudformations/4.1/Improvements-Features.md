  * [Overview](#overview)
  * [Key Changes/Updates](#key-changes/updates)
    * [SignalResource and CreationPolicy](#signalresource-and-creationpolicy)
    * [Update Stack](#update-stack)
    * [Additional Notes](#additional-notes)



## Overview
The goal of this page is to document the Cloudformation changes associated with 4.3. Cloudformation Update Stack is the main feature, however there are a couple of others that should be noted. 


## Key Changes/Updates

### SignalResource and CreationPolicy
 We support the 'SignalResource' api call which can either be made directly via an API call (such as AWS SDK) or via the cfn-signal command from the aws-cfn-bootstrap toolkit available for instances. Resources that can be signaled are: AutoScaling Groups, Instances, and Wait Conditions. A CreationPolicy is necessary to use signals during creation, and we support signals during update as part of the Rolling Update portion of AutoScaling Groups.


### Update Stack
 Updating a stack involves updating resources that were created during a Create Stack call. Tags, parameters, or the template itself can be changed. New resources can be created, existing resources can be deleted or modified. Eucalyptus supports modification of all of the following resource types.


* [AWS::AutoScaling::AutoScalingGroup](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html)
* [AWS::AutoScaling::LaunchConfiguration](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-launchconfig.html)
* AWS::AutoScaling::ScalingPolicy
* [AWS::CloudFormation::Stack](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html)
* [AWS::CloudFormation::WaitConditionHandle](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitconditionhandle.html)
* [AWS::CloudFormation::WaitCondition](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-waitcondition.html)
* AWS::CloudWatch::Alarm
* AWS::EC2::DHCPOptions
* AWS::EC2::EIPAssociation
* AWS::EC2::EIP
* AWS::EC2::Instance
* AWS::EC2::InternetGateway
* AWS::EC2::NatGateway
* AWS::EC2::NetworkAclEntry
* AWS::EC2::NetworkAcl
* AWS::EC2::NetworkInterfaceAttachment
* AWS::EC2::NetworkInterface
* AWS::EC2::Route
* AWS::EC2::RouteTable
* AWS::EC2::SecurityGroupEgress
* AWS::EC2::SecurityGroupIngress
* AWS::EC2::SecurityGroup
* AWS::EC2::SubnetNetworkAclAssociation
* AWS::EC2::Subnet
* AWS::EC2::SubnetRouteTableAssociation
* AWS::EC2::VolumeAttachment
* AWS::EC2::Volume
* AWS::EC2::VPCDHCPOptionsAssociation
* AWS::EC2::VPCGatewayAttachment
* AWS::EC2::VPC
* AWS::ElasticLoadBalancing::LoadBalancer
* AWS::IAM::AccessKey
* AWS::IAM::Group
* AWS::IAM::InstanceProfile
* AWS::IAM::Policy
* AWS::IAM::Role
* AWS::IAM::User
* AWS::IAM::UserToGroupAddition
* AWS::S3::Bucket

Update Stack PhasesUpdate stack consists of the following stack phases


* UPDATE_IN_PROGRESS – all new stack resources are created, and modifications to existing resources (with the exception of deleting resources from inner stacks) are made.
* UPDATE_COMPLETE_CLEANUP_IN_PROGRESS – all obsolete stack resources are deleted.
* UPDATE_COMPLETE – update is complete.
    * Cancel Update can only occur during the UPDATE_IN_PROGRESS phase

    

Error PhasesHere are some phases that occur when errors occur:


* UPDATE_FAILED – the update process has failed, rollback will begin shortly
* UPDATE_ROLLBACK_IN_PROGRESS – existing resources that had been modified are modified back to their original state
* UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS – new resources that had been created during update are deleted
* UPDATE_ROLLBACK_COMPLETE – update rollback has completed
* UPDATE_ROLLBACK_FAILED – an error occurred during the UPDATE_ROLLBACK_IN_PROGRESS phase
    * Continue Update Rollback can be called to resume Update Rollback if UPDATE_ROLLBACK_FAILED occurs.

    



If any errors occur during the various cleanup phases, since all that is happening is that resources are being deleted, delete is retried, and if continually unsuccessful, resources are simply detached from the stack.

Limitations (Scope of Update Stack Implementation)What parts of Update Stack we support and don't support.

From the list of AWS topics:


* [Update Behaviors of Stack Resources](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html)– This mentions 'No Interruption', 'Some Interruption', and 'Needs Replacement'– we support the fields in resources the same way that AWS does.
* [Modifying a Stack Template](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-get-template.html)– We support direct template modification, but have no GUI to build templates.
* [Updating Stacks Using Change Sets](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)– We do not support change sets.
* [Updating Stacks Directly](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html)– As above, we support direct template modification, as well as updates to stacks through the 'UpdateStack' API call (euca2ools, aws-cli, or AWS SDK)
* [Monitoring the Progress of a Stack Update](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-monitor-stack.html)– the API supports DescribeStacks, DescribeStackEvents, and DescribeStackResources. We should have the same stack events that AWS does.
* [Canceling a Stack Update](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn--stack-update-cancel.html)– We support cancel update stack as AWS does.
* [Prevent Updates to Stack Resources](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)– We do not support preventing updates to stack resources.
* [Continue Rolling Back an Update](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-continueupdaterollback.html) – We support the ContinueUpdateRollback API call but euca2ools does not currently have a method to call this.


### Additional Notes

* In addition, we do not support Notification Configurations as we do not implement SNS or SQS.
* We also support UpdatePolicy, which is only supported at AWS on AutoScalingGroups. We support the "RollingUpdate" section, but not the "ScheduledAction" section because Eucalyptus does not support Autoscaling Scheduled Actions.





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:cloudformations]]
