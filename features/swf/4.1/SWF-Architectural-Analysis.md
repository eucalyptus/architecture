* [Description](#description)
* [Tracking](#tracking)
* [Use Cases](#use-cases)
* [Analysis](#analysis)
  * [SWF-overview](#swf-overview)
  * [API](#api)
* [Elements](#elements)
  * [Place holder #1](#place-holder-#1)
* [Workflows & Coordination](#workflows-&-coordination)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
  * [Place holder #1](#place-holder-#1)
* [Behaviours](#behaviours)
  * [References](#references)
* [Notes](#notes)



# Description
As a cloud developer, I want to use workflow services so that higher level services such as CloudFormation, ELB, Imaging Service can be implemented systematically and more conveniently. As a cloud user, I should be able to program application workflows conveniently without dealing with state management problems that are irrelevant to application logic.


# Tracking

* ARCH-71
* ARCH-82
* Status: Step #1, initial draft


# Use Cases

*  **CloudFormation** :certain CloudFormation operations require the support from SWF.[[Cloudformation (ARCH-69/PRD-93/PRD-94)|cloudformations-4.1-spec]].


*  **ImagingService:** ImagingService performs a series of steps to convert incoming images. These steps are currently coordinated via IS-specific workflows. Certain details of the workflows are irrelevant to the job that IS should carry out. By decoupling workflow's state mgmt problems from actual application logic, the IS can be refactored into much simpler code, and improvements to the IS can be done quicker.


*  **ELB** :Similarly to ImagingService, ELB currently runs a ELB-specific workflows to carry out multi-step operations. Use of SWF will simplify its code structure.


*  **Future Services:** In fact, any higher-level services that requires coordination of service components (e.g., RDS) will benefit from SWF. SWF can be a foundation of new services added into Eucalyptus.


# Analysis

## SWF-overview
SWF api simplifies programming workflows by decoupling state management from application logic. SWF api provides well-defined types and states (via event history) that is commonly useful when constructing workflows. From application developer perspectives, they don't have to deal with state management problems, but only focus on developing application logic using the accumulated states that is available via SWF api. This model simplifies the development of SWF service (API) itself because the service only stores and retrieves states associated with a workflow, without concerning transitions between service's states. For example, scheduling an activity task is done by a decision task (which is part of application), and the allocation of the task is also done by a worker (which is again the application). All the service should do is to stores the history of well-defined events and deliver them via API. There is no implicit state transformations across API calls. In comparison, implementing other services such as ELB can be more complex because to implement an API call, there are internal states that is transformed in series, often by distributed components (e.g., ELB VM).


## API
SWF API can be grouped as follows ([http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-api-by-category.html](http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-api-by-category.html)):


* Actions related to activities
    * PollForActivityTask, RespondActivityTaskCompleted, RespondActivityTaskFailed, RespondActivityTaskCancelled, RecordActivityTaskHeartBeat

    
* Actions related to deciders
    * PollForDecisionTask,RespondDecisionTaskCompleted

    
* Actions related to workflow executions
    * RequestCancelWorkflowExecution, StartWorkflowExecution, SignalWorkflowExecution, TerminateWorkflowExecution

    
* Actions related to administration
    * RegisterActivityType, DeprecateActivityType, RegisterWorkflowType, DeprecateWorkflowType, RegisterDomain, DeprecateDomain
    * ListActivityTypes, DescribeActivityTypes, ListWorkflowTypes, DescribeWorkflowType, DescribeWorkflowExecution, ListOpenWorkflowExecution, ListClosedWorkflowExecution, CountOpenWorkflowExecutions, CountClosedWorkflowExecutions, GetWorkflowExecutionHistory
    * ListDomains, DescribeDomains, CountPendingActivityTasks, CountPendingDecisionTasks

    


# Elements

* 
## SWF Service

    * Service API implementation

    
* 
## Timeout Manager

    * To respond to time-outs (workflow, task, etc)
    * Timer-driven

    


## Place holder #1
Place holder #1 description.




# Workflows & Coordination



# Interactions

# Abstractions

## Place holder #1

# Behaviours

## References

* [http://aws.amazon.com/swf/](http://aws.amazon.com/swf/)
* [http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-workflow-exec-lifecycle.html](http://docs.aws.amazon.com/amazonswf/latest/developerguide/swf-dev-workflow-exec-lifecycle.html)
* [http://docs.aws.amazon.com/amazonswf/latest/apireference/Welcome.html](http://docs.aws.amazon.com/amazonswf/latest/apireference/Welcome.html)


# Notes

* notes #1



*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:swf]]
