[[Architectural Discovery Checklist_ PRD-93 CloudFormations|Architectural-Discovery-Checklist_-PRD-93-CloudFormations]]



| Resource | AWS::AutoScaling::AutoScalingGroup | 
| Supported Parameters | <ul><li>Availability Zones (List of Strings, required strangely, can use Fn:GetAZs)</li><li>Cooldown (String)</li><li>DesiredCapacity (String)</li><li>HealthCheckGracePeriod (String)</li><li>HealthCheckType (String)</li><li>LaunchConfigurationName (String, existing  or reference to AWS:AutoscalingGroup::LaunchConfiguration)</li><li>LoadBalancerNames (String, existing  or reference to WS::ElasticLoadBalancing::LoadBalancer</li><li>MaxSize (String)</li><li>MinSize (String)</li><li>Tags (String)</li></ul> | 
| Unsupported Parameters | <ul><li>NotificationConfiguration</li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources. (Launch Configurations and ELB). Fail if failure on create.   3) Call "euscale-create-autoscaling-group" with parameters extracted from above, assuming dependent resources exist. Fail if command fails.   4) Creation is synchronous.    Update:   1) Parse template, fail if invalid.   2) Do a "diff" against existing resources. New LaunchConfigurations and ELB items need to be created. Rollback if failure on create new resources   3) Call "euscale-update-autoscaling-group" with parameters extracted above, fail if command fails   4) Delete old "replace on update" parameters. (ELB, Launch Config)    Delete:   1) call "euscale-delete-autoscaling-group" <name>. Fail if failure in command. | 
| Resource | AWS::AutoScaling::LaunchConfiguration | 
| Supported Parameters | <ul><li>BlockDeviceMappings (block device mapping)</li><li>EbsOptimized (boolean)</li><li>IamInstanceProfile (String – can be Ref: AWS::EC2::SecurityGroup)</li><li>ImageId (String – references a pre-existing item, required)</li><li>InstanceMonitoring (Boolean)</li><li>InstanceType (String – references a pre-existing item, required)</li><li>KernelId (String)</li><li>KeyName (String)</li><li>RamDiskId (String)</li><li>SecurityGroups (list of strings, can be existing groups or Ref: AWS::EC2::SecurityGroup)</li></ul> | 
| Unsupported Parameters | <ul><li>AssociatePublicIpAddress</li><li>SpotPrice</li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources. (SecurityGroup, IamInstanceProfile . Fail if failure on create.   3) Call "euscale-create-launch-config" with parameters extracted from above, assuming dependent resources exist. Fail if command fails.   4) Creation is synchronous.    Update:   1) Parse template, fail if invalid.   2) Create dependent resources. (SecurityGroup, IamInstanceProfile . Fail if failure on create.   3) Call "euscale-create-launch-config" with parameters extracted from above, assuming dependent resources exist. Fail if command fails. Give the group a different name than the existing one. (See below)   4) Call "euscale-delete-launch-config" on the existing group   5) Somehow rename the new group to the old one    \[Note: do we need to be able to rename a launch config under the hood?]   If not, we can delete/create new one? (makes rollback hard)    Delete:   1) call "euscale-delete-launch-config" <name>. Fail if failure in command | 
| Resource | AWS::AutoScaling::ScalingPolicy | 
| Supported Parameters | <ul><li>AdjustmentType (String, required)</li><li>AutoScalingGroupName (String, required, Ref: AWS::AutoScaling::AutoScalingGroupName, possible ARN of existing group)</li><li>Cooldown (String)</li><li>ScalingAdjustment (String)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources. (AutoScalingGroup). Fail if failure on create.   3) Call "euscale-put-scaling-policy" with parameters extracted from above, assuming dependent resources exist. Fail if command fails.   4) Creation is synchronous.    Update:   1) Same as create. "euscale-put-scaling-policy" updates existing policies.   Delete:   1) call "euscale-delete-policy" <name>. Fail if failure in command | 
| Resource | AWS::CloudFormation::Authentication | 
| Supported Parameters | N/A | 
| Unsupported Parameters | N/A | 
| Workflows | No resources are created from this template object by itself, it is referenced by other resources (namely AWS::CloudFormation::Init metadata) | 
| Resource | AWS::CloudFormation::Init | 
| Supported Parameters | N/A | 
| Unsupported Parameters | N/A | 
| Workflows | No resources are created from this template object by itself, it is referenced by other resources (namely within "Metadata" portion of AWS::EC2::Instance and used by cloud-init scripts within instance. | 
| Resource | AWS::CloudFormation::Stack | 
| Supported Parameters | <ul><li>Template URL (String, required URL to S3 bucket path)</li><li>TimeoutInMinutes (String)</li><li>Parameters (Parameters)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Run "cloud-formations-create-stack" on template parameter. Fail if fails & rollback.    Update:   1) Parse template, find stacks that have changed (if any).   2) run "cloud-formations-update-stack" on stacks that have changed.    Delete:   1) run "cloud-formations-delete-stack" <stack name>    Note: this is for nested stacks. | 
| Resource | AWS::CloudFormation::WaitCondition | 
| Supported Parameters | N/A | 
| Unsupported Parameters |  | 
| Workflows | No resources are created from this template, but there is a workflow where it waits until it receives enough signals from the "AWS::CloudFormation::WaitConditionHandle" to start stack creation/update. (??????) | 
| Resource | AWS::CloudFormation::WaitConditionHandle | 
| Supported Parameters | N/A | 
| Unsupported Parameters |  | 
| Workflows | ???????? | 
| Resource | AWS::CloudWatch::Alarm | 
| Supported Parameters | <ul><li>ActionsEnabled (String)</li><li>AlarmActions (List of String)</li><li>AlarmDescription (String)</li><li>ComparisonOperator (String, required)</li><li>Dimensions (List of Dimension)</li><li>EvaluationPeriods (String, required)</li><li>InsufficientDataActions (String, required)</li><li>MetricName (String, required)</li><li>OKActions (List of String)</li><li>Period (String, required)</li><li>Statistic (String, required)</li><li>Threshold (String, required)</li><li>Unit (String)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Call "euwatch-put-metric-alarm" . Fail if command fails.   3) Creation is synchronous.    Update:   1) Same as create. "euwatch-put-metric-alarm" updates existing alarms.   Delete:   1) call "euscale-delete-alarms" <name>. Fail if failure in command | 
| Resource | AWS::EC2::EIP | 
| Supported Parameters | InstanceId (String) | 
| Unsupported Parameters | Domain | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources. (Instance). Fail if failure on create.   3) call "euca-allocate-address". Fail if command fails.   4) Creation is synchronous   Update:   1) ??? (supported?)   Delete:   1) call "euca-release-addresses". Fail if failure in command | 
| Resource | AWS::EC2::EIPAssociation | 
| Supported Parameters | <ul><li>EIP (String, existing or Ref: AWS::EC2::EIP, required as no VPC)</li><li>InstanceId (String)</li></ul> | 
| Unsupported Parameters | <ul><li>AllocationId</li><li>NetworkInterfaceId</li><li>PrivateIpAddress</li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources. (Instance, EIP). Fail if failure on create.   3) call "euca-associate-address". Fail if command fails.   4) Creation is synchronous   Update   1) Parse template, fail if invalid.   2) Create new dependent resources.   3) call "euca-associate-address" in the new resources.   4) call "euca-disassociate-address" in the old resources   5) Delete old resources   Delete   1) Call "euca-disassociate-address". Fail if command fails | 
| Resource | AWS::EC2::Instance | 
| Supported Parameters | <ul><li>AvailabilityZone (String, maybe referenced? )</li><li>BlockDeviceMappings (block device mappings)</li><li>IamInstanceProfile (String ref AWS::IAM::InstanceProfile)</li><li>ImageId (String, required)</li><li>InstanceType (String)</li><li>KernelId (String)</li><li>KeyName (String)</li><li>Monitoring (Boolean)</li><li>RamdiskId (String)</li><li>SecurityGroups (list of strings, can be existing groups or Ref: AWS::EC2::SecurityGroup)</li><li>Volumes (list of EC2 MountPoints)</li></ul> | 
| Unsupported Parameters | <ul><li>DisableApiTermination </li><li>EbsOptimized </li><li>NetworkInterfaces </li><li>PlacementGroupName </li><li>PrivateIpAddress </li><li>SecurityGroupIds</li><li>SourceDestCheck</li><li>SubnetId</li><li>Tenancy </li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources. (Volume, Security Groups, etc). Fail on failure to create.   3) call "euca-run-instances". Keep instance id.   4) Keep calling "euca-describe-instances <instanceid> until in "running state". (Success) or other bad state. ("Fail").   Update   1) Parse template, fail if invalid.   2) Check differences. Some can be changed by doing things like euca-monitor-instances. Others require create and delete (euca-terminate-instances).   Delete   1) Call "euca-terminate-instances". Fail if command fails    TODO: prepare appropriate instances to figure out how to use the metadata cloud init stuff. | 
| Resource | AWS::EC2::SecurityGroup | 
| Supported Parameters | <ul><li>GroupDescription (string, required)</li><li>SecurityGroupEgress (list of ec2 security group rule (not sure if Ref: is allowed))</li><li>SecurityGroupIngress (list of ec2 security group rule (not sure if Ref: is allowed))</li><li>Tags (List of tags)</li></ul> | 
| Unsupported Parameters | <ul><li>VpcId</li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) call "euca-create-group". Fail on failure.   3) call "euca-authorize" on group to deal with security-group ingress/egress rules (TODO: modify tools to allow egress rules, maybe use API). Fail on failure, rollback.    Update   1) Parse template, fail if invalid.   2) Check differences. Some fields require deleting and re-creating security group. Rules do not, but description do. Appropriate commands are euca-revoke, euca-authorize, euca-create-group, euca-delete-group.    Delete   1) Call "euca-delete-group" <group name>. Fail if command fails | 
| Resource | AWS::EC2::SecurityGroupIngress | 
| Supported Parameters | GroupName (String)   GroupId (String)   IpProtocol (String, required)   CidrIp (String)   SourceSecurityGroupName (String, existing group ARN or Ref: AWS::EC2::SecurityGroup)   SourceSecurityGroupId (String, existing group ARN or Ref: AWS::EC2::SecurityGroup)   SourceSecurityGroupOwnerId (String)   FromPort (String)   ToPort (String) | 
| Unsupported Parameters | Above parameters in a VPC context | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources (SecurityGroup), fail on failure.   3) Run "euca-authorize" with appropriate parameters. Fail on failure   4) Operation is synchronous   Update:   1) Parse template, fail if invalid.   2) Create dependent resources (SecurityGroup), fail on failure,   3) Run euca-authorize and euca-revoke as necessary   4) Delete unreferenced dependencies (Security Group)   Delete:   1) Run "euca-revoke" on the rule described. | 
| Resource | AWS::EC2::Volume | 
| Supported Parameters | <ul><li>AvailabilityZone (required)</li><li>Size (Number)</li><li>SnapshotId (String)</li><li>Tags (List of Tags)</li></ul> | 
| Unsupported Parameters | <ul><li>Iops</li><li>VolumeType (value should be "standard")</li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Run "euca-create-volume", note volume id.   3) Keep calling "euca-describe-volumes <instanceid> until "success". (Success) or other bad state. ("Fail").   Update:   I do not believe you can update volumes.   Delete:   1) Run "euca-delete-volume" volume id.   2) Further steps depend on the "Deletion Policy" attribute.   Note: Some steps may be necessary to detatch a volume as well, or possibly terminate an instance if it is the root volume. | 
| Resource | AWS::EC2::VolumeAttachment | 
| Supported Parameters | <ul><li>Device (String, required)</li><li>InstanceId (String, required, can reference existing instance id or Ref: AWS::EC2::Instance)</li><li>VolumeId (String, required, can reference existing volume id or Ref: AWS::EC2::Volume)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Create dependent resources (volume/instance)   3) Run "euca-attach-volume" with appropriate parameters   4) ??? Not sure if synchronous or should call euca-describe-instances on instance-id to see if volume attached.   Update:   1) Parse template, fail if invalid   2) Create new dependent resources   3) Run "euca-detach-volume" with old parameters   4) Run "euca-attach-volume" with new parameters   5) Same check as create for success   Delete:   1) Run "euca-detach-volume" with appropriate parameters (may need to stop instance?) | 
| Resource | AWS::ElasticLoadBalancing::LoadBalancer | 
| Supported Parameters | <ul><li>AvailabilityZones (list of strings)</li><li>HealthCheck (HealthCheck type – inline)</li><li>Instances (List of strings – can be Ref: AWS::EC2::Instance)</li><li>Listeners (list of listeners – inline)</li><li>Policies (list of policies --inline)</li></ul> | 
| Unsupported Parameters | <ul><li>AppCookieStickinessPolicy</li><li>LBCookieStickinessPolicy</li><li>Scheme</li><li>SecurityGroups</li><li>Subnets</li></ul> | 
| Workflows | Create:   1) Parse template, fail if invalid   2) Create dependent resources (instances?)   3) Run "eulb-create-lb" with appropriate parameters.   4) Wait until load balancer is created ("eulb-describe-lbs"), check for state   5) Run "eulb-configure-healthcheck" as needed.   6) Run "eulb-enable-zones-for-lb" as needed.   7) Run "eulb-create-policy" as needed.   8) Run "eulb-create-listener" as needed.   Update:   1) Parse template, fail if invalid   2) Create dependent (new) resources   3) May run eulb-delete-(policy/listener) as needed, then eulb-create-(policy/listener)   Delete:   1) Run "eulb-delete-lb" <name> | 
| Resource | AWS::IAM::AccessKey | 
| Supported Parameters | <ul><li>Serial (Integer, increased value → key rotation)</li><li>Status (String, required)</li><li>Username (String, required, can be a AWS::IAM::User reference)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid.   2) Run "euare-useraddkey", gather output.   3) Run "euare-usermodkey" as needed for status.   Update:   1) Parse template, fail if invalid.   2) If status changes, run "euare-usermodkey"   3) If serial increments, delete and add the key again   Delete:   1) Run "euare-userdelkey" with the key info | 
| Resource | AWS::IAM::Group | 
| <ul><li>Supported Parameters</li></ul> | <ul><li>Path (String)</li><li>Policies (List of AWS::IAM::Policy types, looks like inline only. Can reference this object from an AWS::IAM::Policy Groups section)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid   2) Run "euare-groupcreate" with appropriate parameters   3) Run "euare-groupaddpolicy" as necessary.   Update:   1) Parse template, fail if invalid   2) Run "euare-groupmod" as necessary (path change?)   3) Run "euare-groupdelpolicy" and "euare-groupaddpolicy" as necessary   Delete:   1) Run "euare-groupdel" | 
| Resource | AWS::IAM::InstanceProfile | 
| Supported Parameters | ?? | 
| Unsupported Parameters | ?? | 
| Workflows | ?? | 
| Resource | AWS::IAM::Policy | 
| Supported Parameters | ?? | 
| Unsupported Parameters | ?? | 
| Workflows | ?? | 
| Resource | AWS::IAM::Role | 
| Supported Parameters | ?? | 
| Unsupported Parameters | ?? | 
| Workflows | ?? | 
| Resource | AWS::IAM::User | 
| Supported Parameters | <ul><li>Path (String)</li><li>Groups (List of groups)</li><li>LoginPorfile (Password: String)</li><li>Policies (embedded)</li></ul> | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid   2) Run "euare-usercreate" with appropriate parameters   3) Run "euare-useraddpolicy" as necessary.   4) Run "euare-groupadduser" as necessary.   Update:   1) Parse template, fail if invalid   2) Run "euare-usermod" as necessary (path change?)   3) Run "euare-useraddpolicy" and "euare-userdelpolicy" as necessary   4) Run "euare-groupadduser" and "euare-groupremoveuser" as nessary   Delete:   1) Run "euare-userdel" | 
| Resource | AWS::IAM::UserToGroupAddition | 
| Supported Parameters | GroupName (String, required, existing group)   Users (list of string, can use references) | 
| Unsupported Parameters |  | 
| Workflows | Create:   1) Parse template, fail if invalid   2) Create dependent resources (User)   3) Run "euare-groupadduser" as necessary   Update:   1) Parse template, fail if invalid   2) Run "euare-groupadduser" and "euare-groupremoveuser" as necessary   Delete:   1) Run "euare-groupremoveuser" as necessary | 
| Resource | AWS::S3::Bucket | 
| Supported Parameters | ?? | 
| Unsupported Parameters | ?? | 
| Workflows | How do you create a bucket?? | 



*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:cloudformations]]
