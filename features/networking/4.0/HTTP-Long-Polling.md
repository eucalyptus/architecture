
# Overview
 _Drawn from the related RFC_ 

HTTP"long polling" attempts to minimize latency in state/message delivery, the use of network capacity (for data transfer), and the use of processing resources typically associated with no-transition polling events. As an extension to the message exchange pattern, clients supply state (view) information which identifies the context in which the server should evaluate the need to transfer state. Combined the approach leads to a simple implementation, low latency state change propagation, low resource utilization and preserves the failure tolerance characteristics of traditional "short" polling.

With the traditional or "short polling" technique, a client sends regular requests to the server and each request attempts to "pull" any available events or data. If there are no events or data available, the server returns an empty response and the client waits for some time before sending another poll request. The polling frequency depends on the latency that the client can tolerate in retrieving updated information from the server. This mechanism has the drawback that the consumed resources (server processing and network) strongly depend on the acceptable latency in the delivery of updates from server to client. If the acceptable latency is low (e.g., on the order of seconds), then the polling frequency can cause an unacceptable burden on the server, the network, or both.

In contrast with such "short polling", "long polling" attempts to minimize both the latency in server-client message delivery and the use of processing/network resources. The server achieves these efficiencies by responding to a request only when a particular event, status, or timeout has occurred. Once the server sends a long poll response, typically the client immediately sends a new long poll request. Effectively, this means that at any given time the server will be holding open a long poll request, to which it replies when new information is available for the client. As a result, the server is able to asynchronously "initiate" communication.

The basic life cycle of an application using HTTP long polling is as follows:


1. The client makes an initial request and then waits for a response.
1. The server defers its response until an update is available or until a particular status or timeout has occurred.
1. When an update is available, the server sends a complete response to the client.
1. The client typically sends a new long poll request, either immediately upon receiving a response or after a pause to allow an acceptable latency period.

When doing HTTP long-polling a client will call the operation as normally while the server responds to the request only when a particular event, status, or timeout has occurred. Once the server sends a long poll response, the client immediately sends a new long poll request. This means that long-polling clients will be blocked waiting on the server which will be holding open their long poll request. Those connections are serviced only when there is new information for the client. So then:


* Clients receive state changes promptly after they occur, independent of the polling interval as in "short" polling.
* State is only transferred to the client when a state change has occurred.
* Clients resume polling immediately after completion of the last polling event and block until one of a number of conditions occur:
    * New state is available
    * The operation's timeout triggers and closes the connection (the client should be setting its timeout to be meaningfully higher than the servers)
    * A network error occurs

    
* Failure scenarios in this model have negligible consequencesin terms of any of:
    * latency: the subsequent poll will happen promptly after the failure resolves and obtain the state
    * complexity: no special action needs to be taken to handle a failure

    


# Applications in Eucalyptus
Initial discussion is focused on describe and workflow-like operations related to EDGE and the Imaging Service.


## Describe Operations: State Transfer using HTTP Long-Polling
The above model describes a generic interaction where a client performs  _some_  call to the server and the server delivers events. Here this is specialized to cover operations which transfer shared state information with both concurrent and remote (invisible) sources of change.

The class of operations in question is characterized by requests which are :


*  **Shared State Model:** a model of some state which changes over time and needs to be referenced by multiple consumer.
*  **State Identifier**  **:** an identifier which uniquely identifies a particular arrangement of the model state and is carried along with the model. The identifier can then be subsequently supplied by a client indicating the state which was last present on the client. This can be a UUID, but can also be a collection of attributes that, in sum, uniquely identify the state; a composite identifier. No identifier identifies the null state.

The elaboration on mere HTTP Long-Polling is that the server uses the supplied identifier to determine whether an event has occurred that the client needs to receive. The server tracks the current identifier and uses it to classify and handle arriving clients. In addition the server tracks those persistent long polling clients awaiting state change.

Here is how the server behaves for the two sources of stimulus (the client and server itself):


*  **Client: Calls with different identifier:** different state on client, return the ground-truth state.
*  **Client: Calls with same identifier:**  store the client reference along with its arrival time for the duration of the server operation's timeout.
*  **Server: Model state change:** perform atomic state update, get new identifier, supply new state along with identifier to all currently pending clients.
*  **Server: Timeout a client:** if a client has lingered with the same state identifier for longer than the timeout the server closes the connection.




### HTTP Long-Polling in EDGE
In the forthcoming EDGE network architecturethe CC can no longer be in the data path. An architectural priority is that it **_also no longer be in the control path_** . More specifically, that the interaction pattern between the ground-truth for the network model definition (at the EC2 service) and the EDGE network elements is that of a client calling a server operation. This has many implications which are reviewed in the following sections.


### Push Model
The current push message flow has a substantial and negative impact on the system's extensibility and implementation complexity. A change to the systems behaviour which is end-to-end involves changes to each intermediary:


* to accommodate the new data types
* introduce the new operations
* address topological multiplicity (i.e., many-to-one relationships)
* manage state caching and dissemination or polling
* core changes (e.g., EC2 service) are dictated by additions at the edge
* actuating the push becomes more complex to both execute and configure as the number of EDGE elements grows
    * NOTE: here I imply, but now simply state, that there will be more and, moreover, they won't all be zone-level.

    


### Pull Model w/ long-polling
Conversely, a long-polling approach would entirely defined by a single operation with 3 parts:


* the data model used by the operation to represent state
* the state identifiers
* the URL of the operation
* (optionally) any ancilliary attributes or payload associated with the state

A notable difference can be seen when considering the question: What needs to change in order to introduce a new EDGE service.


### Node Controller Up-Calls
For this to be implemented the Node Controller has to make an up-call to the user-facing service in question. For this to work the following need be satisfied:


*  **Authentication** :the service needs to be able to authenticate the NC's request. This can be done using either: the same approach as for ExportVolume or through a combination of AssumeRole (to get temporary access keys and secret keys) followed by a boto/euca2ools or similar up-call using those credentials
*  **Service Address:** the correct address for the service needs to be used. This is prerequisite for a number of functionalities (metadata, instance DNS, etc.) and must be present already. Today the information can be drawn from the service information sent down in polling requests. This should serve only as an interim solution as the topological changes resulting from splitting out user-facing services will cause the EC2 services to have multiple and simultaneously active endpoints.


### Topological Considerations
There are several perspectives from which topology is a consideration here. Both indicate that

Node ControllerThe principle consideration here is the NC's ability to make service requests to the EC2 and related service endpoints. This is required functionality beyond this case for the following things:


* User workloads must be able to access metadata
* User workloads must be able to access service endpoints
* User workloads must be able to resolve instance DNS
* Node Controller must be able to download images (which in 4.0 would be coming from the same set of hosts as the EC2 service occupies)
* Node Controller must be able to upload bundles (which in 4.0 would be coming from the same set of hosts as the EC2 service occupies)
* Instances must be routable to the user.
* The EC2 services must beroutable to the user.
    * Combined they imply the instances can use that path to reach the user.

    

These requirements imply the ability to access the needed services. Topologies which fail these requirements are not a consideration in the architecture (if they are supportable it is through external means).

Cluster ControllerThe participation of the cluster controller in the flow of information is contraindicated by other objectives of the architecture:


* Support for non-zone level services is not possible or a burden on core EC2 development.
* Changes to the data model require 3 additional pieces of work (inbound, outbound, internal) to be implemented.


## Example Describe Service Operation
For a describe operation the application of long-polling makes sense when:


1. There are many and/or different places in the system where state needs to be transferred.
1. State is captured entirely in the current snapshot (i.e., no intermediate transition information is needed).

A describe operation that supports long-polling must do the following additional things:


* Amend the API to allow clients for specifying the _current state identifier._ 
* Track the current state identifier.
* Track the needed state for inbound requests that request the current state identifier(the Context or Channel for the Java stack).
* Trigger response to all blocked inbound requests when a change in the state snapshot occurs.
*  _Optional:_ When appropriate, only respond when the requested subset of the current state changes.

A client which calls such a describe operation has to do the following additional things:


* Adjust timeout behaviour to conform to the describe operation's timeout plus a skew factor to avoid spurious client-initiated timeouts.
* Handle describe operation timeouts correctly (i.e., it is not an error, there was no state change).
* Change the calling pattern to constantly poll the describe operation and only apply the state obtained on a successful call.
* Track the identifier for the current local state. No local state corresponds with a null state identifier.










### Extension to Handle Client-to-Server State Transfer
For the Imaging Service there are two





*****

[[tag:confluence]]
[[tag:rls-4.0]]
[[tag:networking]]
