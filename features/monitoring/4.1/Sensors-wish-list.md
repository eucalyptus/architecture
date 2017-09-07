
1. Timing data for each phase of run-instance path
1. Java Common
    1. Threads per thread-pool
    1. lock count
    1. db connection count
    1. Timing for db queries
    1. Per-service API call failure count

    
1. time for Describe\* calls to each cluster from CLC

    
    1. DescribeServices
    1. DescribeInstances
    1. DescribeResources
    1. DescribeSensors

    
1. NC
    1. Network usage (not-euca specific)
    1. VM migrations incoming
    1. VM migrations outgoing
    1. space left in blob-store
    1. #of cores used, available
    1. RAM used, available
    1. Monitoring thread execution time (e.g. is it taking longer and longer or constant)

    
1. SC
    1. Snapshot uploads in progress
    1. Bandwidth per snap
    1. Aggregate bandwidth

    
    1. Concurrent volume operations
    1. Connectivity status to backend
    1. Successful pings & failed pings

    

    
1. Run-Instance timing
    1. Synchronous path
    1. Async full path (pending→running)

    
1. CloudWatch
    1. Queue depth for data processing queues
    1. Incoming metrics per time unit
    1. Processed metrics per time unit (to detect dropped metrics)
    1. Alarms
    1. Number evaluated per minute
    1. Number transitioned per minute

    
    1. Total number of data points in the system

    
1. AutoScaling
    1. Number of scaling groups
    1. Scaling actions taken

    
1. ELB
    1. backend service pings succeeded & failed
    1. event listeners fired (e.g. vm failure detected and removed from rotation??)

    
1. VPC/Networking
    1. Public IPs in system
    1. Public IPs in use
    1. VPC count
    1. Subnet count
    1. midonet API calls failed
    1. midonet API calls succeeded

    





*****

[[tag:confluence]]
[[tag:rls-4.1]]
[[tag:monitoring]]
