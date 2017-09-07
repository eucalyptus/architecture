
## Overview
Cloudformation is an AWS operation that coordinates resource/application setup with a descriptive .JSON file. Resources are grouped together in a  _stack_ . Stacks can be created, updated, and deleted. Currently Eucalyptus supports create and delete operations. This document discusses the generalities of the update operation.

Update starts with an existing stack (initial state), and makes changes to it (final state) 


* Some resources may exist in the initial state, and not in the final state. (In this case, update stack will delete these resources)
* Some resources may exist in the final state, and not in the initial state. (In this case, update stack will create these resources).
* Some resources may exist in both states, unchanged. (In this case, update stack will do nothing).
* Some resources may exist in both states, but have some different properties. (In this case, the resources will be updated. There are a few cases)
    * Some resources and properties allow no interruption to the resource. Any property of AWS::Cloudwatch::Alarm, for example.
    * Some resources and properties allow some interruption to the resource, without having to create a replacement resource. For example, changing an ImageType for an AWS::EC2::Instance that is backed by an EBS image can be done by restarting the instance. No new instance id will need to be created.
    * Some resources and properties require a replacement resource to be created. Changing the ImageType for an AWS::EC2::Instance that is an instance store instance requires a new instance to be created, which will have a different instance id than the previous instance. In this case the resource's physical id will be different after update.
    * Some resources and properties can not be updated at all. AWS::Cloudformation::WaitCondition is such an example. An attempt to update a stack with such a resource will fail.

    

Finally, update stack supports rollback, converting the stack back to the initial state if something goes wrong. This means that new resources must be created before the old resources are deleted, to make sure the original stack state can be restored. These are the general conditions of the update stack process.


## Create Stack/Delete Stack Comparisons
In order to determine what questions need to be answered to formulate a general update stack algorithm, lets look at a high level description of create stack and delete stack workflows. We will not consider the failure cases as yet.


### Create Stack Workflow

1. Synchronous portion of the Create Stack service call. Parse template, evaluate/validate parameters and conditions. Determine resource dependency order. Return if error.
1. Begin asynchronous workflow. Perform stack initialization operations.
1. For each resource, in dependency order,
    1. Create the resource.

    
1. Perform stack finalization functions (create outputs, for example).

In addition to the steps above, describe-stack-resources (for each resource) will return resource status of CREATE_IN_PROGRESS and CREATE_COMPLETE while resources are being created. describe-stack-events will create events of each type as well. describe-stacks will return a stack status of CREATE_IN_PROGRESS and CREATE_COMPLETE for the stack itself as well.


### Delete Stack Workflow

1. Synchronous portion of the Delete Stack service call. Make sure stack exists, etc. Return if error.
1. Begin asynchronous workflow. Perform stack delete initialization operations.
1. For each resource, in dependency order,
    1. Delete the resource.

    
1. Perform stack finalization functions (delete the stack)

In addition to the steps above, describe-stack-resources (for each resource) will return resource status of DELETE_IN_PROGRESS and DELETE_COMPLETE while resources are being deleted. describe-stack-events will create events of each type as well. describe-stacks will return a stack status of DELETE_IN_PROGRESS and DELETE_COMPLETE for the stack itself as well. Once the stack and resources have been deleted, however, all of the above calls will generally return nothing.


### Analysis of Create and Delete Stack Workflow
Both the create and delete stack workflows have the following operations, presumably the update stack workflow would have the same.


* A pre-condition check. (In the create case, the stack must not exist, etc. In the delete case, the stack must exist, etc.)
* Global initialization. (After the synchronous workflow has occurred, but before any resources have changed).
* A delegation of operations per resource. (For example, create stack delegates resource creation to each resource). The hope here is that the logic to update a given resource can be contained within the resource itself.
* Global finalization.

In addition, both create and delete stack add events and change status values for describe-stacks, describe-stack-resources, and describe-stack-events.


## Questions for Analysis #1
The following questions can be answered by running test cases against AWS, and are derived from the information in the previous section.


1.  **What preconditions must be satisfied for update stack to kick off?** 
1.  **What events/resource status changes occur during one or more successful update stack runs?** 

The general precondition question will be looked at more generally a little later on, but let's try the simplest test first.

 **Test run # 1** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. | 
| Final Stack | No change from the initial stack. Even the parameter values are the same. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | It is interesting that AWS acknowledges a special case where no updates are to be performed, a NO-OP is a legitimate update. One precondition that must occur is that the final stack must be 'different' from the initial stack. (Further investigation will occur). | 

We have determined one (perhaps unexpected) precondition that must be satisfied for a stack to be updated, let's try a couple items that we expect should fail.

 **Test run # 2** 

| Initial Stack | No stack at all. | 
| Final Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation Error (Stack <stack-name> does not exist.) | 
| Notes | This is as expected. | 

 **Test run # 3 (really 13 tests)** 

| Initial Stack | Any stack whose current state is one of CREATE_IN_PROGRESS, CREATE_FAILED (set disableRollback to true and give it a bad stack), ROLLBACK_IN_PROGRESS, ROLLBACK_FAILED (one way is to give a created resource a dependency), ROLLBACK_COMPLETE, DELETE_IN_PROGRESS, DELETE_COMPLETE (use the stack id as the stack name). Or any stack whose current state is in one of the following update states: (so one update stack call must have been started already): UPDATE_IN_PROGRESS, UPDATE_COMPLETE_CLEANUP_IN_PROGRESS, UPDATE_ROLLBACK_IN_PROGRESS, UPDATE_ROLLBACK_FAILED, UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. | 
| Final Stack | Any stack with differences from the initial stack. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation Error (Stack:<stack-id> is in <bad_state> state and can not be updated. | 
| Notes | We must check that the stack state is not one of the above as a precondition to launch the update. Valid update states are the remaining states not described above: CREATE_COMPLETE, UPDATE_COMPLETE, UPDATE_ROLLBACK_COMPLETE. | 

There may be additional preconditions, or specific cases where update is not allowed, but for now, in order to Whether the state check or identical stack check is done first will be determined later, but both must be done for update stack.

To address the second question above, lets run some tests that actually update a stack.

 **Test run # 4** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values, and the values are the same as in the initial case. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | The stack status workflow for updates in a successful case are CREATE_COMPLETE->UPDATE_IN_PROGRESS->UPDATE_COMPLETE_CLEANUP_IN_PROGRESS->UPDATE_COMPLETE. New resources have the same status progression as they would in the create stack case, and are created during the UPDATE_IN_PROGRESS stack state. Resources are not deleted until the UPDATE_COMPLETE_CLEANUP_IN_PROGRESS stack state, and while stack events signifying delete progress are created, the resources themselves maintain the CREATE_COMPLETE status until finally deleted. (This is not the case during delete stack or rollback after create).  | 

We know when (in the progress above) create and delete resources occur. Let's try a test run with an actual update to a resource.

 **Test run # 5** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information. (In addition, monitoring 'Instance2' in EC2 shows the instance was restarted in the meantime).</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | The test result is similar to the previous test, but this time a resource ('Instance2') is updated. The resource status workflow for 'Instance2' is CREATE_COMPLETE->UPDATE_IN_PROGRESS->UPDATE_COMPLETE. Rebooting instances is apparently the mechanism to update the instance type of an instance. Work to create and update resources can apparently be done in parallel if there are no dependencies on each other. (So the idea of "do adds first, then updates, then deletes" is not the appropriate algorithm for update stack.)  | 

We have just seen an example of an update using "Some Interruptions". Let's do something that requires "Replacement".

 **Test run # 6** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', and 'ImageId' changes, but also to an EBS backed image. This should cause 'Instance2' to be updated with one field in the 'Some Interruption' category, and one field in the 'Replacement' category. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. The resource status reason was no longer empty, but 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.</li><li>'Instance2' maintained its resource status as UPDATE_IN_PROGRESS but changed its reason to 'Resource creation initiated'. (As in the create case – this is also when the physical id changed). A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information. (In addition, monitoring 'Instance2' in EC2 shows the instance was restarted in the meantime).</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance2' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'UPDATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance2' to DELETE_COMPLETE. However, the actual resource status did not change, and remained 'UPDATE_COMPLETE').</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | The test result is similar to the previous test, but interestingly, the resource that is replacing the original instance in 'Instance2' also uses 'Instance2' as its logical resource id. It now makes sense why DELETE_\* resource status values are not propagated during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS as it appears there may be more than one 'resource' affected. No restarting of instances occurred, so it appears 'Requires Replacement' trumps 'Some interruption' which makes sense. 'Requires Replacement' deletes the original resource during the cleanup phase of update. | 

So we have seen what happens with the "Some interruption" and "Requires Replacement" update tasks. Let's see what happens when we have some nested dependencies on updates.

 **Test run # 7** 

| Initial Stack | A stack with one VPC ('VPC'), one subnet ('Subnet'), and one instance ('Instance1'), and three parameters ('ImageId', 'InstanceType', and 'CidrBlock). 'VPC' uses 'CidrBlock' as a property value. 'Subnet' uses 'VPC' as a property value, and 'Instance1' uses 'Subnet', 'ImageId', and 'ImageId' as property values. | 
| Final Stack | The same stack as the initial stack, with the 'CidrBlock' property value changed. This should require at least the 'VPC' resource to require replacement, and the effects may cascade to the other resources. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands. We will not check the resource status during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS as we know they remain what they were before that state.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'VPC' changed resource status to UPDATE_IN_PROGRESS with 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.</li><li>'VPC' maintained its resource status as UPDATE_IN_PROGRESS with 'Resource creation initiated'. A stack event was created with this information.</li><li>'VPC' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>'Subnet' changed resource status to UPDATE_IN_PROGRESS with 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.</li><li>'Subnet' maintained its resource status as UPDATE_IN_PROGRESS with 'Resource creation initiated'. A stack event was created with this information.</li><li>'Subnet' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>'Instance1' changed resource status to UPDATE_IN_PROGRESS with 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.</li><li>'Instance1' maintained its resource status as UPDATE_IN_PROGRESS with 'Resource creation initiated'. A stack event was created with this information.</li><li>'Instance1' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE.</li><li>A stack event was created indicating a change of resource status on 'Subnet' to DELETE_IN_PROGRESS.</li><li>A stack event was created indicating a change of resource status on 'Subnet' to DELETE_COMPLETE.</li><li>A stack event was created indicating a change of resource status on 'VPC' to DELETE_IN_PROGRESS.

</li><li>A stack event was created indicating a change of resource status on 'VPC' to DELETE_COMPLETE.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | One thing to notice is that the template text is exactly the same here. We only changed one parameter value. Parameter value changes can be sufficient for a precondition for update. Having said that, once the update started, the list of steps is exactly what we would have expected. Resources that require replacement may require other resources to require replacement as well. | 

Let's try something similar, but just change a field that requires "No Interruption"

 **Test run # 8** 

| Initial Stack | A stack with one VPC ('VPC'), one subnet ('Subnet'), and one instance ('Instance1'), and three parameters ('ImageId', 'InstanceType', and 'CidrBlock). 'VPC' uses 'CidrBlock' as a property value. 'Subnet' uses 'VPC' as a property value, and 'Instance1' uses 'Subnet', 'ImageId', and 'ImageId' as property values. | 
| Final Stack | The same stack as the initial stack, with a Tag: property added to 'VPC'. The property values will remain the same. This should require only a 'No Interruption' change to VPC. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands. We will not check the resource status during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS as we know they remain what they were before that state.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'VPC' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'VPC' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | Resources which have a property that references another resource that has been updated do not automatically have to update themselves. | 

Let's look at a similar example with IAM resources.

 **Test run # 9** 

| Initial Stack | A stack with one IAM Role ('Role'), and one IAM Policy ('Policy'). The policy uses the role as a property value. CAPABILITY_IAM must be used on the stack. There are no parameters. | 
| Final Stack | The same stack as the initial stack, with the policy 'Path' property modified (requires replacement). | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands. We will not check the resource status during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS as we know they remain what they were before that state.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Role' changed resource status to UPDATE_IN_PROGRESS with 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.</li><li>'Role' maintained its resource status as UPDATE_IN_PROGRESS with 'Resource creation initiated'. A stack event was created with this information.</li><li>'Role' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>'Policy' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Policy' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Role' to DELETE_IN_PROGRESS.</li><li>A stack event was created indicating a change of resource status on 'Role' to DELETE_COMPLETE.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | There are examples where dependent resources may need replacement but that the current resource may be able to survive with 'No Interruption'. In this case 'Policy' knew it needed to be updated because {'Ref':'Role'} had changed. | 

Let's look at the same test with the Role not needing replacement.

 **Test run # 10** 

| Initial Stack | A stack with one IAM Role ('Role'), and one IAM Policy ('Policy'). The policy uses the role as a property value. CAPABILITY_IAM must be used on the stack. There are no parameters. | 
| Final Stack | The same stack as the initial stack, with the policy 'Path' property modified (requires replacement). | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands. We will not check the resource status during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS as we know they remain what they were before that state.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Role' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Role' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | In this example, Policy did not need to change, as its dependent resource did not change its Ref: value. | 

This is enough information for now to determine what happens in general for successful update stack calls. Let's look a little more closely at what other precondition checks may be required.


## More Analysis of Preconditions
It is clear that an update stack call will not return an error of type 400 Validation error (No updates are to be performed.) if at least one property in a resource is different between the old and new template. Let's try a couple of other scenarios.

 **Test run # 11** 

| Initial Stack | Any stack. | 
| Final Stack | The same stack as the initial stack, with some whitespace added anywhere outside JSON values. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | A simple exact comparison of equality is insufficient to describe a stack as "no updates to be performed". | 

 **Test run # 12** 

| Initial Stack | Any stack with a top level "Description" field. | 
| Final Stack | The same stack as the initial stack, with a change to the "Description" field. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | "Description" change alone is not enough to allow a stack update. | 

 **Test run # 13** 

| Initial Stack | Any stack with a top level "AWSTemplateFormatVersion" field. (The only allowed value is 2010-09-09) | 
| Final Stack | The same stack as the initial stack, with a change to the "AWSTemplateFormatVersion" field. (Since 2010-09-09 is the only value, all we can do here is omit the field altogether). | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | "AWSTemplateFormatVersion" change alone is not enough to allow a stack update. | 

 **Test run # 14** 

| Initial Stack | Any stack with some "Outputs" fields. | 
| Final Stack | The same stack as the initial stack, with any change to the change to the "Outputs" fields. This can include adding new outputs, deleting some outputs, changing some field values, or removing the whole section. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | "Outputs" change alone is not enough to allow a stack update. | 

 **Test run # 15** 

| Initial Stack | Any stack with some "Outputs" fields. | 
| Final Stack | The same stack as the initial stack, with any change to the change to the "Outputs" fields, but also a change to a value that is known to allow a stack update (such as a resource property). | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. Outputs have successfully changed at the very end of the update. | 
| Notes | An update stack operation does the same operations on a stack as a create stack operation, including output evaluation, when it is run successfully. | 

 **Test run # 16** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and three parameters ('ImageId' and 'InstanceType' and 'ImageId2'). Both instances use both parameters as property values, with 'ImageId2' not used by either instance. | 
| Final Stack | The same stack as the initial stack, with an new value for 'ImageId2'. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | Very interesting. It appears resources may be the only thing that matters, if even parameters that are not used by resources are different, and an update is not allowed. | 

 **Test run # 17** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and three parameters ('ImageId' and 'InstanceType' and 'ImageId2'). Both instances use both parameters as property values, with 'ImageId2' not used by either instance, and ImageId and ImageId2 having the same value. | 
| Final Stack | The same stack but in this case the ImageId field in 'Instance2' is changed from {"Ref":"ImageId"} to {"Ref":"ImageId2"}. Both values are the same, however. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | This gives enough information to show that resources are evaluated as fully as possible to determine if any updates will occur. | 

 **Test run # 18** 

| Initial Stack | Any stack with a mapping that is not used by any resource. | 
| Final Stack | The same stack with the mapping value described in the initial stack changed. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | Mappings are evaluated to determine if they affect resource properties. If they do not, they are ignored for update. | 

 **Test run # 19** 

| Initial Stack | Any stack with a mapping that is used by a resource. | 
| Final Stack | The same stack with the mapping value described in the initial stack changed. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack.. The stack incorporated the new value as expected. | 
| Notes | Mappings are evaluated to determine if they affect resource properties. If they do, they are not ignored for update. Full evaluation of resources, as much as possible, are done in the synchronous portion of the update stack call. | 

 **Test run # 20** 

| Initial Stack | A stack with three instances ('Instance1', 'Instance2', 'Instance3'), hard coded property values. No dependencies among them. In addition there are 3 conditions ('Condition1', 'Condition2', 'Condition3') each associated via a "Condition": attribute on the corresponding instance. Condition1 and Condition2 are set to evaluate to true, and Condition 3 is set to evaluate to false. ({"Fn::Equals" : \["x","x"]} and {"Fn::Equals" : \["x","y"]}). | 
| Final Stack | The same stack with Condition 2 and 3 set to true, and Condition 1 set to false. No changes are made to the Resource blocks. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. As one would expect, 'Instance1' is deleted and 'Instance3' is created, in the same order as in Test Run #4. | 
| Notes | Conditions are also evaluated to determine which resources to include in the update stack call. This is to be expected. | 

 **Test run # 21** 

| Initial Stack | A stack with three instances ('Instance1', 'Instance2', 'Instance3'), hard coded property values. No dependencies among them. In addition there are 3 conditions ('Condition1', 'Condition2', 'Condition3') each associated via a "Condition": attribute on the corresponding instance. Condition1 and Condition2 are set to evaluate to true, and Condition 3 is set to evaluate to false. ({"Fn::Equals" : \["x","x"]} and {"Fn::Equals" : \["x","y"]}). One additional condition 'Condition4' is created, not associated with any resource. | 
| Final Stack | The same stack with only the Condition 4 value changed. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | As the condition that changed did not affect any resources, this result is expected. | 

 **Test run # 22** 

| Initial Stack | A stack with a top level 'Metadata' field. | 
| Final Stack | The same stack with the top level 'Metadata' field changed (values changed) | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes |  | 

 **Test run # 23** 

| Initial Stack | A stack with a top level 'Metadata' field. | 
| Final Stack | The same stack with the top level 'Metadata' field removed. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | This result, together with the previous result, suggests that the top level 'Metadata' field does not affect stack update at all. | 

 **Test run # 24** 

| Initial Stack | A stack with a top level 'Metadata' field. | 
| Final Stack | The same stack with the top level 'Metadata' field removed. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | This result, together with the previous result, suggests that the top level 'Metadata' field does not affect stack update at all. | 

So far we have determined that for all top level fields 'Metadata', 'AWSTemplateFormatVersion', and 'Outputs' do not affect whether or not a stack can be updated. 'Mappings', 'Conditions', and 'Parameters' only affect whether a stack can be updated if after evaluation, one or more resource level fields have been changed. Obviously resource changes can allow a stack to be updated. What about other top level fields?

 **Test run # 25** 

| Initial Stack | Any stack at all. | 
| Final Stack | The same stack with and additional field "a":"b" | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (Invalid template resource property 'a') | 
| Notes | I am not certain that Eucalyptus currently supports the exact set of known top level fields (AWSTemplateFormatVersion, Mappings, Metadata, Conditions, Outputs, Mappings, Parameters, Resources), but it should. This would disallow any other top level field checking. | 

We know now which top level fields are checked to determine whether a stack can be updated or not. We also know that within the Resource blocks, changing 'Properties' values allows a stack to be updated.


### Analysis of Fields within a Resource block.
We would like to know if any other fields within a Resources block will allow an 'Update Stack' to occur.

 **Test run # 26** 

| Initial Stack | A stack with one instance ('Instance1'), hard coded property values. In addition, there is a "Metadata" field within the instance. (Not a top level template field). | 
| Final Stack | The same stack with a change to the "Metadata" field for 'Instance1'. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance1' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | Differences in 'Metadata' at the resource level can trigger a stack update. | 

 **Test run # 27** 

| Initial Stack | Something like AWS's LAMP stack example ([https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/LAMP_Single_Instance.template](https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/LAMP_Single_Instance.template)). A stack that contains a resource with a CreationPolicy. | 
| Final Stack | The same stack with a modification to the CreationPolicy (perhaps increase the timeout, or remove the CreationPolicy altogether). | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | Differences in 'CreationPolicy' at the resource level can not trigger a stack update. (We don't support CreationPolicy at the moment, anyway) | 

 **Test run # 28** 

| Initial Stack | A stack with three instance ('Instance1', 'Instance2', 'Instance3'), hard coded property values. Instance2 has a 'DependsOn' clause for 'Instance1'. | 
| Final Stack | Same stack. Instance2 has a 'DependsOn' clause for 'Instance3'. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | DependsOn is not used to determine whether or not a stack update will occur. (Although it may play a role in resource update/creation order when update stack does start to run). | 

 **Test run # 29** 

| Initial Stack | A stack with three instance ('Instance1', 'Instance2', 'Instance3'), hard coded property values. Instance2 has a 'DependsOn' clause for 'Instance1'. | 
| Final Stack | Same stack. Instance2 has a 'DependsOn' clause for 'Instance3'. | 
| Results | Update Stack Call returned failure synchronously. Error message: 400 Validation error (No updates are to be performed.) | 
| Notes | DependsOn is not used to determine whether or not a stack update will occur. (Although it may play a role in resource update/creation order when update stack does start to run). | 



There is no need to actually run a test for the 'DeletionPolicy' field. Documentation from AWS ([http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html)) details that the DeletionPolicy field alone can not trigger an update, but we can force a change by making a change somewhere else in the stack. This does raise a question however: can resource attributes that would not trigger an update otherwise be changed by the suggestion in the referenced documentation, such as adding a dummy resource like a WaitConditionHandle.



 **NOTE: A test was run on the above, changing the Deletion policy with 1 instance and a Wait Condition Handle. The Instance had an UPDATE_COMPLETE status on it, suggesting it is also updated then.** 

 **Test run # 30** 

| Initial Stack | A stack with three instance ('Instance1', 'Instance2', 'Instance3'), hard coded property values. Instance2 has a 'DependsOn' clause for 'Instance1'. | 
| Final Stack | Same stack. Instance2 has a 'DependsOn' clause for 'Instance3', but we also add a new resource 'Dummy', which is a wait condition handle. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. Events in the stack occur as expected, 'Dummy' being created. No references are made to updating any other resources. However, there is a difference in delete order after updating the stack. If we deleted the initial stack, Instance2 and Instance3 are deleted first, then Instance1. Deleting the updated stack deletes 'Dummy', 'Instance2' and 'Instance1' are deleted, then 'Instance3'. | 
| Notes | Wholesale stack evaluation is done, including Policies, and DependsOn clauses, if the stack is updated at all. Even on resources that do not appear to need updating. | 




## Answers to Questions for Analysis #1
So given the above test results, what can we say about the questions posed in the earlier part of this document?


1.  **What preconditions must be satisfied for update stack to kick off?** 

    An initial stack must exist, and be in one of CREATE_COMPLETE, UPDATE_COMPLETE, or UPDATE_ROLLBACK_COMPLETE states.

    The final stack must have new resources, old resources removed, or existing resources with a change to either the Properties: or Metadata: section of the resource. Implicit changes are fine, such as if function values like Ref: change. 

    Other resource fields, such as DeletionPolicy are not used to calculate whether an update should occur, but the new values should be honored if a stack update occurs.
1.  **What events/resource status changes occur during one or more successful update stack runs?** 
    1. The stack goes into an UPDATE_IN_PROGRESS state.
    1. Resources that need to be added/updated are done so, in dependency order, creating resource status workflows of CREATE_IN_PROGRESS->CREATE_COMPLETE and UPDATE_IN_PROGRESS->UPDATE_COMPLETE.
    1. Items that need to be deleted, such as deleted resources, or the old resources in a "Needs Replacement" update are not yet changed.


    1. The stack goes into an UPDATE_COMPLETE_ROLLBACK_IN_PROGRESS state.


    1. Resources that need to be deleted are done so, in an order that lets dependencies work. Stack events are created for these resources, with status values of DELETE_IN_PROGRESS->DELETE_COMPLETE, but the status does not propagate to the resource itself. This is due to the fact that Replacement resources have the same Logical Resource Id as the resouces they are replacing, and the Replacement resources should have status UPDATE_COMPLETE.


    1. The stack goes into an UPDATE_COMPLETE state.



    



Other items that occur during the Create Stack workflow, such as template parsing, determining resource dependency order, and generating output, occur at the same place in the Update Stack workflow as they do in the create stack workflow.




## Questions for Analysis #2
Given the answers to the first set of questions, a couple of more questions come to mind, some specific refinements of the initial results.


1.  **Considering AWS specific parameter types, while syntactical validation is done in the "synchronous" portion of the create stack call, valid value parsing (for example: making sure a parameter of type AWS::EC2::Instance::Id actually is an instance id) does not occur until the create stack workflow begins. An error of this type will not cause the create stack call to return an error, but the stack will immediately be in the CREATE_FAILED state, followed by appropriate rollback action if appropriate. What happens in the update case?** 
1.  **Certain resources do not support update. For example AWS::CloudFormation::WaitCondition. If a stack attempts to update this field, does an error return synchronously, or does the failure happen during the workflow?** 
1.  **What events/resource status changes occur during one or more update stack runs that requires rollback?** 
1.  **Suppose some stack 'vandalism' occurs. (Such as manual deletion of resources in the stack). Does Cloudformation verify that all resources that are mentioned in the initial stack still intact? What happens if something happens to these resources?** 
1.  **What happens if UPDATE_ROLLBACK fails?** 
1.  **What happens if an error occurs during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS?** 

Given these new questions, lets kick off some more tests.

 **Test run # 31** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' (of type AWS::EC2::Image::id) and 'InstanceType'). Both instances use both parameters as property values, and the values for InstanceType is the same as the initial case, but the value for 'ImageId' is a nonexistent image id. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'Parameter validation failed: parameter value <bad-value> for parameter name ImageId does not exist'. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | The stack status workflow for updates in a case that requires rollback are CREATE_COMPLETE->UPDATE_IN_PROGRESS->UPDATE_ROLLBACK_IN_PROGRESS->UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS->UPDATE_ROLLBACK_COMPLETE.AWS parameter validation based on data values is done after the workflow 'starts', as in the create case. | 

This test run shows the basic steps that occur during update rollback. We will do more such tests where resources are actually in play, but let's answer question 2 first.

 **Test run # 32** 

| Initial Stack | A modified LAMP stack ([https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/LAMP_Single_Instance.template](https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/LAMP_Single_Instance.template)) which uses a wait condition instead of a creation policy. This requires the addition of a wait condition, and a wait condition handle as new resources, and a change to the cfn-signal command. The following CreationPolicy was removed from the WebServerInstance resource:
```
 "CreationPolicy" : {  "ResourceSignal" : {  "Timeout" : "PT5M"  }  }
```
and the following wait condition (and handle) were added.
```
 "myWaitHandle" : {  "Type" : "AWS::CloudFormation::WaitConditionHandle",  "Properties" : {  }  },   "myWaitCondition" : {  "Type" : "AWS::CloudFormation::WaitCondition",  "DependsOn" : "WebServerInstance",  "Properties" : {  "Handle" : { "Ref" : "myWaitHandle" },  "Timeout" : "300"  }  },
```
in the instance userdata portion of the WebserverInstance resource, the cfn-signal command was changed from:
```
 "# Signal the status from cfn-init\n",  "/opt/aws/bin/cfn-signal -e $? ",  " --stack ", { "Ref" : "AWS::StackName" },  " --resource WebServerInstance ",  " --region ", { "Ref" : "AWS::Region" }, "\n"
```
to
```
 "# Signal the status from cfn-init\n",  "/opt/aws/bin/cfn-signal -e $? ",  " --stack ", { "Ref" : "AWS::StackName" },  " \"", { "Ref" : "myWaitHandle" }, "\"\n"
```
This information is provided as it appears AWS has changed most of their application templates to use CreationPolicy and SignalResource instead of WaitCondition and handles. | 
| Final Stack | The only change from the initial stack is to change the timeout value from myWaitCondition from 300 to 450. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'myWaitCondition' changed resource status to UPDATE_FAILED ('Update to resource type AWS::CloudFormation::WaitCondition is not supported'). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'The following resource(s) failed to update: \[myWaitCondition].' A stack event was created with this information.</li><li>'myWaitCondition' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | Resources being unable to be updated are not checked as 'preconditions' (thank goodness). UPDATE_FAILED can be the state of a resource after update. UPDATE_COMPLETE is likely the final status of a resource after UPDATE_ROLLBACK. There does not appear to be an UPDATE_ROLLBACK_IN_PROGRESS or UPDATE_ROLLBACK_COMPLETE as a resource status, but then again, there isn't a ROLLBACK_IN_PROGRESS or ROLLBACK_COMPLETE status either. The values are CREATE_IN_PROGRESS, DELETE_IN_PROGRESS, CREATE_COMPLETE and DELETE_COMPLETE. If you think about it, in the case that a resource is modified without replacement, update and update rollback are essentially the same operation on a resource. | 

This run showed us some more state in the update rollback process. Let's run a couple more tests to expand our reference to update rollback.

 **Test run # 33** 

| Initial Stack | A stack with three instances ('Instance1', 'Instance2', and 'Instance3'). Each has an ImageId and InstanceType property but the values are hard coded. | 
| Final Stack | A stack with four instances ('Instance2', 'Instance3', 'Instance4', and 'Instance5'). Each has an ImageId and InstanceType property but the values are hard coded, except for Instance 5. Its ImageId and InstanceType values are Ref: from Instance3 and Instance4. Both values are invalid for ImageId and InstanceType. Instance4 Depends on Instance2 and Instance3. Instance2 has a different value in the initial stack for InstanceType, and Instance3 has a different value in the initial stack for ImageId. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance3' changed resource status to UPDATE_IN_PROGRESS. The resource status reason was no longer empty, but 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.

</li><li>'Instance3' maintained its resource status as UPDATE_IN_PROGRESS but changed its reason to 'Resource creation initiated'. (As in the create case – this is also when the physical id changed). A stack event was created with this information.

</li><li>'Instance3' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.

</li><li>A new resource 'Instance4' was created with resource status CREATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance4' maintained its resource status as CREATE_IN_PROGRESS but changed its reason to 'Resource creation initiated'. A stack event was created with this information.

</li><li>'Instance4' changed resource status to CREATE_COMPLETE. A stack event was created with this information.

</li><li>A new resource 'Instance5' was created with resource status CREATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance5' changed resource status to CREATE_FAILED, reason 'Invalid id: "i-d8d4a266" (expecting "ami-...")'. A stack event was created with this information.

</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'The following resource(s) failed to create: \[Instance5]'. A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance5' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance4' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').

</li><li>A stack event was created indicating a change of resource status on 'Instance4' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'UPDATE_COMPLETE').

</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_COMPLETE. However, the actual resource status did not change, and remained 'UPDATE_COMPLETE').

</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE. A stack event was created with this information.

</li></ul> | 
| Notes | Quite a lot happened in this stack update. In a successful case (if instance 5 came up correctly), the following items should have occurred (not necessarily in this order. 'Instance1' would be deleted, 'Instance2' would be updated (via stop/start instance), 'Instance3' would be "replaced' (new instance spun up and old instance terminated), 'Instance4' and 'Instance5' would be created. Instead, all of the above happens except for instance 1 being deleted and the old instance for instance 3 being terminated, as a rollback must occur. Rollback terminates the new instances ('Instance4', 'Instance5', and the replacement instance for instance3, and reverses the stop/start instance (with another start/stop instance) on 'Instance2'. We have also seen that the transition for a non-replacement update both in update and update rollback is UPDATE_IN_PROGRESS->UPDATE_COMPLETE. Finally, we note that DELETE_\* status updates do not propagate to resources in UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. | 

This gives a good illustration of what happens in general for update rollback. We still don't know what happens when UPDATE_ROLLBACK fails. This may require some manual intervention. But since we are doing manual intervention anyway, let's see what happens if we are evil.

 **Test run # 34** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. And by the way, I also terminated 'Instance2' manually. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_FAILED with reason 'This instance 'i-4e2455f0' is not in a state from which it can be stopped.' A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_FAILED with reason 'Resource creation cancelled'. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'The following resource(s) failed to create: \[Instance3]. The following resource(s) failed to update: \[Instance2].' A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance3 to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE. A stack event was created with this information.</li><li>Instance2 remains terminated.</li></ul> | 
| Notes | This test is a mess. Clearly it shows no validation of initial resource state is done before the stack update process begins. When Instance2 fails to update, it simply sets its value to UPDATE_COMPLETE during rollback. This is similar to the behavior when a resource being updated was of type AWS::CloudFormation::WaitCondition. Rollback was immediate with UPDATE_COMPLETE. It makes me wonder what would happen in a situation where a resource allows either No Interruption or Some Interruption with two fields that require more than one method to be called, and the first field changes successfully but the second fails. (ELB for example?) What would rollback look like then? (This is a topic for later sprint investigation). | 

The above did not result in UPDATE_ROLLBACK failing, but did result in a stack that is not in the condition described in the initial template, although rollback did bring it back to the state it was before update was called. I would like to try two similar tests.

 **Test run # 35** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. And by the way, I also stopped 'Instance2' manually. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li><li>Instance2 is now running.</li></ul> | 
| Notes | This is an example that shows rollback does not always restore state to exactly how things were before the update, either from the create state, or user induced changed state. | 

 **Test run # 36** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with three instances ('Instance2', 'Instance3', and 'Instance 4') and two parameters ('ImageId' and 'InstanceType'). 'Instance2' and 'Instance3' use both parameters as property values, but 'Instance4' uses bogus parameters to trigger rollback. 'Instance3' depends on 'Instance2', and 'Instance4' depends on both 'Instance2' and 'Instance4'.. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. In a timing dependent move, 'Instance2' will be terminated after its update is complete, but before the rollback occurs. This will hopefully trigger a rollback failure. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance4') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance4' changed resource status to CREATE_FAILED (Invalid id: "i-da702864" (expecting "ami-...")). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS (The following resource(s) failed to create: \[Instance4].). A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_FAILED (This instance 'i-da702864' is not in a state from which it can be stopped.). A stack event was created with this information.A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_ROLLBACK_FAILED (The following resource(s) failed to update: \[Instance2].). A stack event was created with this information.</li></ul> | 
| Notes | This example shows that if an update operation fails during rollback, no further action is taken, it is just UPDATE_ROLLBACK_FAILED. | 

We now see that no real checking is done for tinkering with the stack outside of the set of CloudFormation operations. We have also seen what happens when errors occur during the pre-cleanup phases of both update and update rollback. What happens when there are errors in the cleanup phase? Let's try some tests with some resources we can put dependencies on.

 **Test run # 37** 

| Initial Stack | A stack with two security groups ('SG1' and 'SG2') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). No parameters in the stack. | 
| Final Stack | A stack with two security groups ('SG2' and 'SG3') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). No parameters in the stack. Before updating, 'SG1' is used as a security group for an instance, making it unable to be deleted. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('SG3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'SG3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'SG1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'Instance1' to DELETE_FAILED (resource sg-0da0f86b has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'Instance1' to DELETE_FAILED (resource sg-0da0f86b has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After several minutes, a stack event was created indicating a change of resource status on 'Instance1' to DELETE_FAILED (resource sg-0da0f86b has a dependent object). The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_COMPLETE (Update successful. One or more resources could not be deleted.). A stack event was created with this information.</li></ul> | 
| Notes | Failures during cleanup do not trigger rollback. Delete operations that caused failures are also retried, slowly. (This was surprising). Ultimately however, as cleanup is not as necessary as other things to finish the update stack, all offensive resources that can't be deleted are simply disassociated from the stack. UPDATE_COMPLETE is the final stack state. | 

 **Test run # 38** 

| Initial Stack | A stack with two security groups ('SG1' and 'SG2') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). No parameters in the stack. | 
| Final Stack | A stack with two security groups ('SG2' and 'SG3') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). Three instances ('Instance 1', 'Instance 2', and 'Instance 3'), 'Instance 1' depends on 'SG3', 'Instance2' depends on 'Instance 1', and 'Instance 3' depends on 'Instance 2'. 'Instance 3' has bogus values for 'ImageId' and 'InstanceType'. Timing here is critical, but 'SG3' will be used as a security group to an instance outside of the stack before 'Instance3' fails. This is setup to cause failure during update rollback cleanup. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('SG3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'SG3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance1') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance1' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance2') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_FAILED (Invalid id: "bogus" (expecting "ami-...")). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS (The following resource(s) failed to create: \[Instance3].). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.

</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance2' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>A stack event was created indicating a change of resource status on 'Instance2' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'SG3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_FAILED (resource sg-ab104bcd has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_FAILED (resource sg-ab104bcd has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_FAILED (resource sg-ab104bcd has a dependent object). The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE (Update successful. One or more resources could not be deleted.). A stack event was created with this information.</li></ul> | 
| Notes | Failures during rollback cleanup do not "error out". (Not sure what to do here anyway, can't rollback a rollback). Delete operations that caused failures are also retried, slowly. (This was less surprising, given the previous test result). As in the previous result, all resources that can not be cleaned up during rollback are simply disassociated with the stack, eventually. UPDATE_ROLLBACK_COMPLETE is the final stack state. | 

The cleanup operations between update and update rollback (non-propegation of delete, retry of delete, and ultimately disassociation of failing resources on failure, with a final 'success' state, regardless) shows that the mechanism of cleanup is similar in both cases. We now have enough information to answer our second batch of questions.


## Answers to Questions for Analysis #1
So given the above test results, what can we say about the questions posed in the earlier part of this document?


1.  **What preconditions must be satisfied for update stack to kick off?** 

    An initial stack must exist, and be in one of CREATE_COMPLETE, UPDATE_COMPLETE, or UPDATE_ROLLBACK_COMPLETE states.

    The final stack must have new resources, old resources removed, or existing resources with a change to either the Properties: or Metadata: section of the resource. Implicit changes are fine, such as if function values like Ref: change. 

    Other resource fields, such as DeletionPolicy are not used to calculate whether an update should occur, but the new values should be honored if a stack update occurs.
1.  **What events/resource status changes occur during one or more successful update stack runs?** 
    1. The stack goes into an UPDATE_IN_PROGRESS state.
    1. Resources that need to be added/updated are done so, in dependency order, creating resource status workflows of CREATE_IN_PROGRESS->CREATE_COMPLETE and UPDATE_IN_PROGRESS->UPDATE_COMPLETE.
    1. Items that need to be deleted, such as deleted resources, or the old resources in a "Needs Replacement" update are not yet changed.


    1. The stack goes into an UPDATE_COMPLETE_ROLLBACK_IN_PROGRESS state.


    1. Resources that need to be deleted are done so, in an order that lets dependencies work. Stack events are created for these resources, with status values of DELETE_IN_PROGRESS->DELETE_COMPLETE, but the status does not propagate to the resource itself. This is due to the fact that Replacement resources have the same Logical Resource Id as the resouces they are replacing, and the Replacement resources should have status UPDATE_COMPLETE.


    1. The stack goes into an UPDATE_COMPLETE state.



    



Other items that occur during the Create Stack workflow, such as template parsing, determining resource dependency order, and generating output, occur at the same place in the Update Stack workflow as they do in the create stack workflow.




## Questions for Analysis #2
Given the answers to the first set of questions, a couple of more questions come to mind, some specific refinements of the initial results.


1.  **Considering AWS specific parameter types, while syntactical validation is done in the "synchronous" portion of the create stack call, valid value parsing (for example: making sure a parameter of type AWS::EC2::Instance::Id actually is an instance id) does not occur until the create stack workflow begins. An error of this type will not cause the create stack call to return an error, but the stack will immediately be in the CREATE_FAILED state, followed by appropriate rollback action if appropriate. What happens in the update case?** 
1.  **Certain resources do not support update. For example AWS::CloudFormation::WaitCondition. If a stack attempts to update this field, does an error return synchronously, or does the failure happen during the workflow?** 
1.  **What events/resource status changes occur during one or more update stack runs that requires rollback?** 
1.  **Suppose some stack 'vandalism' occurs. (Such as manual deletion of resources in the stack). Does Cloudformation verify that all resources that are mentioned in the initial stack still intact? What happens if something happens to these resources?** 
1.  **What happens if UPDATE_ROLLBACK fails?** 
1.  **What happens if an error occurs during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS?** 

Given these new questions, lets kick off some more tests.

 **Test run # 31** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' (of type AWS::EC2::Image::id) and 'InstanceType'). Both instances use both parameters as property values, and the values for InstanceType is the same as the initial case, but the value for 'ImageId' is a nonexistent image id. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'Parameter validation failed: parameter value <bad-value> for parameter name ImageId does not exist'. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | The stack status workflow for updates in a case that requires rollback are CREATE_COMPLETE->UPDATE_IN_PROGRESS->UPDATE_ROLLBACK_IN_PROGRESS->UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS->UPDATE_ROLLBACK_COMPLETE.AWS parameter validation based on data values is done after the workflow 'starts', as in the create case. | 

This test run shows the basic steps that occur during update rollback. We will do more such tests where resources are actually in play, but let's answer question 2 first.

 **Test run # 32** 

| Initial Stack | A modified LAMP stack ([https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/LAMP_Single_Instance.template](https://s3-us-west-2.amazonaws.com/cloudformation-templates-us-west-2/LAMP_Single_Instance.template)) which uses a wait condition instead of a creation policy. This requires the addition of a wait condition, and a wait condition handle as new resources, and a change to the cfn-signal command. The following CreationPolicy was removed from the WebServerInstance resource:
```
 "CreationPolicy" : {  "ResourceSignal" : {  "Timeout" : "PT5M"  }  }
```
and the following wait condition (and handle) were added.
```
 "myWaitHandle" : {  "Type" : "AWS::CloudFormation::WaitConditionHandle",  "Properties" : {  }  },   "myWaitCondition" : {  "Type" : "AWS::CloudFormation::WaitCondition",  "DependsOn" : "WebServerInstance",  "Properties" : {  "Handle" : { "Ref" : "myWaitHandle" },  "Timeout" : "300"  }  },
```
in the instance userdata portion of the WebserverInstance resource, the cfn-signal command was changed from:
```
 "# Signal the status from cfn-init\n",  "/opt/aws/bin/cfn-signal -e $? ",  " --stack ", { "Ref" : "AWS::StackName" },  " --resource WebServerInstance ",  " --region ", { "Ref" : "AWS::Region" }, "\n"
```
to
```
 "# Signal the status from cfn-init\n",  "/opt/aws/bin/cfn-signal -e $? ",  " --stack ", { "Ref" : "AWS::StackName" },  " \"", { "Ref" : "myWaitHandle" }, "\"\n"
```
This information is provided as it appears AWS has changed most of their application templates to use CreationPolicy and SignalResource instead of WaitCondition and handles. | 
| Final Stack | The only change from the initial stack is to change the timeout value from myWaitCondition from 300 to 450. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'myWaitCondition' changed resource status to UPDATE_FAILED ('Update to resource type AWS::CloudFormation::WaitCondition is not supported'). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'The following resource(s) failed to update: \[myWaitCondition].' A stack event was created with this information.</li><li>'myWaitCondition' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li></ul> | 
| Notes | Resources being unable to be updated are not checked as 'preconditions' (thank goodness). UPDATE_FAILED can be the state of a resource after update. UPDATE_COMPLETE is likely the final status of a resource after UPDATE_ROLLBACK. There does not appear to be an UPDATE_ROLLBACK_IN_PROGRESS or UPDATE_ROLLBACK_COMPLETE as a resource status, but then again, there isn't a ROLLBACK_IN_PROGRESS or ROLLBACK_COMPLETE status either. The values are CREATE_IN_PROGRESS, DELETE_IN_PROGRESS, CREATE_COMPLETE and DELETE_COMPLETE. If you think about it, in the case that a resource is modified without replacement, update and update rollback are essentially the same operation on a resource. | 

This run showed us some more state in the update rollback process. Let's run a couple more tests to expand our reference to update rollback.

 **Test run # 33** 

| Initial Stack | A stack with three instances ('Instance1', 'Instance2', and 'Instance3'). Each has an ImageId and InstanceType property but the values are hard coded. | 
| Final Stack | A stack with four instances ('Instance2', 'Instance3', 'Instance4', and 'Instance5'). Each has an ImageId and InstanceType property but the values are hard coded, except for Instance 5. Its ImageId and InstanceType values are Ref: from Instance3 and Instance4. Both values are invalid for ImageId and InstanceType. Instance4 Depends on Instance2 and Instance3. Instance2 has a different value in the initial stack for InstanceType, and Instance3 has a different value in the initial stack for ImageId. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance3' changed resource status to UPDATE_IN_PROGRESS. The resource status reason was no longer empty, but 'Requested update requres the creation of a new physical resource; hence creating one'. A stack event was created with this information.

</li><li>'Instance3' maintained its resource status as UPDATE_IN_PROGRESS but changed its reason to 'Resource creation initiated'. (As in the create case – this is also when the physical id changed). A stack event was created with this information.

</li><li>'Instance3' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.

</li><li>A new resource 'Instance4' was created with resource status CREATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance4' maintained its resource status as CREATE_IN_PROGRESS but changed its reason to 'Resource creation initiated'. A stack event was created with this information.

</li><li>'Instance4' changed resource status to CREATE_COMPLETE. A stack event was created with this information.

</li><li>A new resource 'Instance5' was created with resource status CREATE_IN_PROGRESS. A stack event was created with this information.

</li><li>'Instance5' changed resource status to CREATE_FAILED, reason 'Invalid id: "i-d8d4a266" (expecting "ami-...")'. A stack event was created with this information.

</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'The following resource(s) failed to create: \[Instance5]'. A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance5' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance4' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').

</li><li>A stack event was created indicating a change of resource status on 'Instance4' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'UPDATE_COMPLETE').

</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_COMPLETE. However, the actual resource status did not change, and remained 'UPDATE_COMPLETE').

</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE. A stack event was created with this information.

</li></ul> | 
| Notes | Quite a lot happened in this stack update. In a successful case (if instance 5 came up correctly), the following items should have occurred (not necessarily in this order. 'Instance1' would be deleted, 'Instance2' would be updated (via stop/start instance), 'Instance3' would be "replaced' (new instance spun up and old instance terminated), 'Instance4' and 'Instance5' would be created. Instead, all of the above happens except for instance 1 being deleted and the old instance for instance 3 being terminated, as a rollback must occur. Rollback terminates the new instances ('Instance4', 'Instance5', and the replacement instance for instance3, and reverses the stop/start instance (with another start/stop instance) on 'Instance2'. We have also seen that the transition for a non-replacement update both in update and update rollback is UPDATE_IN_PROGRESS->UPDATE_COMPLETE. Finally, we note that DELETE_\* status updates do not propagate to resources in UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. | 

This gives a good illustration of what happens in general for update rollback. We still don't know what happens when UPDATE_ROLLBACK fails. This may require some manual intervention. But since we are doing manual intervention anyway, let's see what happens if we are evil.

 **Test run # 34** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. And by the way, I also terminated 'Instance2' manually. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_FAILED with reason 'This instance 'i-4e2455f0' is not in a state from which it can be stopped.' A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_FAILED with reason 'Resource creation cancelled'. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS with reason 'The following resource(s) failed to create: \[Instance3]. The following resource(s) failed to update: \[Instance2].' A stack event was created with this information.

</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance3 to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE. A stack event was created with this information.</li><li>Instance2 remains terminated.</li></ul> | 
| Notes | This test is a mess. Clearly it shows no validation of initial resource state is done before the stack update process begins. When Instance2 fails to update, it simply sets its value to UPDATE_COMPLETE during rollback. This is similar to the behavior when a resource being updated was of type AWS::CloudFormation::WaitCondition. Rollback was immediate with UPDATE_COMPLETE. It makes me wonder what would happen in a situation where a resource allows either No Interruption or Some Interruption with two fields that require more than one method to be called, and the first field changes successfully but the second fails. (ELB for example?) What would rollback look like then? (This is a topic for later sprint investigation). | 

The above did not result in UPDATE_ROLLBACK failing, but did result in a stack that is not in the condition described in the initial template, although rollback did bring it back to the state it was before update was called. I would like to try two similar tests.

 **Test run # 35** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with two instances ('Instance2' and 'Instance3') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. And by the way, I also stopped 'Instance2' manually. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE').</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_COMPLETE. A stack event was created with this information.</li><li>Instance2 is now running.</li></ul> | 
| Notes | This is an example that shows rollback does not always restore state to exactly how things were before the update, either from the create state, or user induced changed state. | 

 **Test run # 36** 

| Initial Stack | A stack with two instances ('Instance1' and 'Instance2') and two parameters ('ImageId' and 'InstanceType'). Both instances use both parameters as property values. 'InstanceType' is 't2.micro'. This is in a VPC setup, and the 'ImageId' is an EBS backed image. | 
| Final Stack | A stack with three instances ('Instance2', 'Instance3', and 'Instance 4') and two parameters ('ImageId' and 'InstanceType'). 'Instance2' and 'Instance3' use both parameters as property values, but 'Instance4' uses bogus parameters to trigger rollback. 'Instance3' depends on 'Instance2', and 'Instance4' depends on both 'Instance2' and 'Instance4'.. In this case 'InstanceType' has changed from 't2.micro' to 't2.small', but 'ImageId' remains as it was in the initial stack. This should cause 'Instance2' to be updated with the 'Some Interruption' category. In a timing dependent move, 'Instance2' will be terminated after its update is complete, but before the rollback occurs. This will hopefully trigger a rollback failure. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance4') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance4' changed resource status to CREATE_FAILED (Invalid id: "i-da702864" (expecting "ami-...")). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS (The following resource(s) failed to create: \[Instance4].). A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to UPDATE_FAILED (This instance 'i-da702864' is not in a state from which it can be stopped.). A stack event was created with this information.A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_ROLLBACK_FAILED (The following resource(s) failed to update: \[Instance2].). A stack event was created with this information.</li></ul> | 
| Notes | This example shows that if an update operation fails during rollback, no further action is taken, it is just UPDATE_ROLLBACK_FAILED. | 

We now see that no real checking is done for tinkering with the stack outside of the set of CloudFormation operations. We have also seen what happens when errors occur during the pre-cleanup phases of both update and update rollback. What happens when there are errors in the cleanup phase? Let's try some tests with some resources we can put dependencies on.

 **Test run # 37** 

| Initial Stack | A stack with two security groups ('SG1' and 'SG2') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). No parameters in the stack. | 
| Final Stack | A stack with two security groups ('SG2' and 'SG3') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). No parameters in the stack. Before updating, 'SG1' is used as a security group for an instance, making it unable to be deleted. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('SG3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'SG3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>The stack state changed to UPDATE_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.</li><li>A stack event was created indicating a change of resource status on 'SG1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'Instance1' to DELETE_FAILED (resource sg-0da0f86b has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'Instance1' to DELETE_FAILED (resource sg-0da0f86b has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After several minutes, a stack event was created indicating a change of resource status on 'Instance1' to DELETE_FAILED (resource sg-0da0f86b has a dependent object). The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_COMPLETE (Update successful. One or more resources could not be deleted.). A stack event was created with this information.</li></ul> | 
| Notes | Failures during cleanup do not trigger rollback. Delete operations that caused failures are also retried, slowly. (This was surprising). Ultimately however, as cleanup is not as necessary as other things to finish the update stack, all offensive resources that can't be deleted are simply disassociated from the stack. UPDATE_COMPLETE is the final stack state. | 

 **Test run # 38** 

| Initial Stack | A stack with two security groups ('SG1' and 'SG2') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). No parameters in the stack. | 
| Final Stack | A stack with two security groups ('SG2' and 'SG3') each with an Ingress Rule (port 22, Cidr 0.0.0.0/0). Three instances ('Instance 1', 'Instance 2', and 'Instance 3'), 'Instance 1' depends on 'SG3', 'Instance2' depends on 'Instance 1', and 'Instance 3' depends on 'Instance 2'. 'Instance 3' has bogus values for 'ImageId' and 'InstanceType'. Timing here is critical, but 'SG3' will be used as a security group to an instance outside of the stack before 'Instance3' fails. This is setup to cause failure during update rollback cleanup. | 
| Results | Update Stack Call returned successfully. The stack id returned was the same as the initial stack. The following events occurred afterwards, determined by running repeated describe-\* commands.<ul><li>The stack state changed to UPDATE_IN_PROGRESS. A stack event was created with this information.</li><li>A new resource was created ('SG3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'SG3' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance1') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance1' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance2') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance2' changed resource status to CREATE_COMPLETE. A stack event was created with this information.</li><li>A new resource was created ('Instance3') with resource status CREATE_IN_PROGRESS. A stack event was created with this information.</li><li>'Instance3' changed resource status to CREATE_FAILED (Invalid id: "bogus" (expecting "ami-...")). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_IN_PROGRESS (The following resource(s) failed to create: \[Instance3].). A stack event was created with this information.</li><li>The stack state changed to UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS. A stack event was created with this information.

</li><li>A stack event was created indicating a change of resource status on 'Instance3' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance2' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>A stack event was created indicating a change of resource status on 'Instance2' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>A stack event was created indicating a change of resource status on 'Instance1' to DELETE_COMPLETE. The resource no longer returned a resource status at this point.</li><li>A stack event was created indicating a change of resource status on 'SG3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_FAILED (resource sg-ab104bcd has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_FAILED (resource sg-ab104bcd has a dependent object). However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_IN_PROGRESS. However, the actual resource status did not change, and remained 'CREATE_COMPLETE'.</li><li>After a few minutes, a stack event was created indicating a change of resource status on 'SG3' to DELETE_FAILED (resource sg-ab104bcd has a dependent object). The resource no longer returned a resource status at this point.</li><li>The stack state was changed to UPDATE_ROLLBACK_COMPLETE (Update successful. One or more resources could not be deleted.). A stack event was created with this information.</li></ul> | 
| Notes | Failures during rollback cleanup do not "error out". (Not sure what to do here anyway, can't rollback a rollback). Delete operations that caused failures are also retried, slowly. (This was less surprising, given the previous test result). As in the previous result, all resources that can not be cleaned up during rollback are simply disassociated with the stack, eventually. UPDATE_ROLLBACK_COMPLETE is the final stack state. | 

The cleanup operations between update and update rollback (non-propegation of delete, retry of delete, and ultimately disassociation of failing resources on failure, with a final 'success' state, regardless) shows that the mechanism of cleanup is similar in both cases. We now have enough information to answer our second set of questions.


## Answers to Questions for Analysis #2
So given the above test results, what can we say about the second set of questions posed earlier in this document?


1.  **Considering AWS specific parameter types, while syntactical validation is done in the "synchronous" portion of the create stack call, valid value parsing (for example: making sure a parameter of type AWS::EC2::Instance::Id actually is an instance id) does not occur until the create stack workflow begins. An error of this type will not cause the create stack call to return an error, but the stack will immediately be in the CREATE_FAILED state, followed by appropriate rollback action if appropriate. What happens in the update case?** 

    The same thing happens in the update case as in the create case: parameter validation (i.e. instance is actually an instance id) is done as the first step in the workflow, but after the synchronous call occurs. Update rollback action also occurs, as well.
1.  **Certain resources do not support update. For example AWS::CloudFormation::WaitCondition. If a stack attempts to update this field, does an error return synchronously, or does the failure happen during the workflow?** 

    In this case, the failure is not noticed until the workflow kicks off (after the API call returns), but the offending resource changes its status to UPDATE_FAILED and rollback begins. For the offending resource, the state becomes UPDATE_COMPLETE immediately during rollback.
1.  **What events/resource status changes occur during one or more update stack runs that requires rollback?** 

    Resources that are new have the same status changes as during create. CREATE_IN_PROGRESS->CREATE_COMPLETE. Resources that need to be removed during cleanup use the DELETE_IN_PROGRESS->DELETE_COMPLETE status. Workflows that are updated (not needing replacement) go from UPDATE_IN_PROGRESS->UPDATE_COMPLETE. When rollback occurs, no create operations are necessary, items that need to be modified back to their original state again go to UPDATE_IN_PROGRESS->UPDATE_COMPLETE. The stack workflow for rollback is CREATE_COMPLETE->UPDATE_IN_PROGRESS->UPDATE_ROLLBACK_IN_PROGRESS->UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS->UPDATE_ROLLBACK_COMPLETE.
1.  **Suppose some stack 'vandalism' occurs. (Such as manual deletion of resources in the stack). Does Cloudformation verify that all resources that are mentioned in the initial stack still intact? What happens if something happens to these resources?** 

    No verification of stack state vs initial stack state are done. Errors occur as they would normally. Rollback is attempted where possible.
1.  **What happens if UPDATE_ROLLBACK fails?** 

    In the case that an error occurs before cleanup, the final stack state is simply UPDATE_ROLLBACK_FAILED.
1.  **What happens if an error occurs during UPDATE_COMPLETE_CLEANUP_IN_PROGRESS?** 

    Both the UPDATE_COMPLETE_CLEANUP_IN_PROGRESS state and UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS will ultimately "succeed" if errors occur during delete. Deletes are retried (apparently 3 times in the example shown), and slowly. Offending resources are disassociated with the stack.


## Conclusion (Sprint 0)
We now have enough information to attempt an update stack algorithm for sprint 0. It should go basically like this.


1. Synchronous portion of the Update Stack service call. Determine if stack state is appropriate for update. Parse template, evaluate/validate parameters and conditions. Determine resource dependency order. Determine if updates need to occur at all. Return if error.
1. Begin asynchronous workflow. Perform stack initialization operations.
1. For each resource (in the second stack), in dependency order,
    1. Update the resource. (this requires determining if the resource is new, needs modification, or needs replacement. This logic can occur at the resource level).

    
1. Perform stack cleanup operations (delete all resources from the first stack not in the second, and any 'replaced' resources). (Perhaps keep a list of global list of resources to delete somewhere, populating as update goes along).
1. Perform stack finalization functions (create outputs, for example).

Rollback can be tackled later.


## Additional topics for later

1. Exactly what fields in a Resource are queried to determine if it needs to be updated. Properties and Metadata are checked, DependsOn, DeletionPolicy, and Condition are not. Type would be a difficult one to change without changing properties. We also should check CreationPolicy, and UpdatePolicy.
1. We should implement Cancel Update Stack operation.
1. We should implement the SignalResource operation and CreationPolicy Attribute on Resources.
1. We should look at StackPolicy and IAM.
1. We should look at the UpdatePolicy Attribute on Resources. (Currently only AutoScalingGroup allows this field).
1. We should disallow properties that are not defined for Resources. Originally we wanted to just ignore these fields to maintain (at least a semblance of) compatibility with AWS. But in order to determine what update type we need (No Interruption, Some Interruption, Requires Replacement) we need to check every field in a resource, we should not have to deal with fields that we ignore.
1. We should further explore what happens if part of an update "goes through" on a resource that requires several commands to be executed to change different properties of a resource. (ELB). How do we determine what has changed in actuality?

    

    



*****

[[tag:confluence]]
[[tag:rls-4.3]]
[[tag:cloudformations]]
