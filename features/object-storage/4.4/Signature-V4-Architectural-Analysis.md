* [Description](#description)
* [Tracking](#tracking)
  * [Related Features](#related-features)
* [Analysis](#analysis)
  * [S3 Sigv4 validation](#s3-sigv4-validation)
  * [S3 Sigv4 chunked uploads](#s3-sigv4-chunked-uploads)
  * [Netty pipeline issues](#netty-pipeline-issues)
* [Elements](#elements)
* [Interactions](#interactions)
* [Abstractions](#abstractions)
* [Milestones](#milestones)
  * [Sprint 1](#sprint-1)
  * [Sprint X](#sprint-x)
* [Risks](#risks)
* [References](#references)



# Description
Implement signature V4 support for S3 via Netty. Additionally, resolve existing issues in the S3 / Object Storage pipeline where large file uploads can fail.

Jonathan Halterman was the primary developer, with . Before leaving the company, Jonathan gave a brain dump of this feature and related topics. It was recorded as a screen sharing with audio, [which you can download here](http://git.qa1.eucalyptus-systems.com/lthomas/misc/blob/master/large/Jonathan_Halterman_S3_signature_v4_etc_2017-02-28.mp4).




# Tracking

* Status: Step #1, initial draft


## Related Features
None


# Analysis

## S3 Sigv4 validation
S3 sigv4 validation is similar to Sigv4 validation in other services, but in addition to the initial request validation, individual chunks are signed and need to be validated. Each chunk's signature is a function of the signing key, the payload, and the signature from the previous chunk (which needs to be remembered).


## S3 Sigv4 chunked uploads
S3 applies its own chunking to Sigv4 signed uploads in addition to HTTP's chunking. A single HTTP chunk may contain a partial Sigv4 chunk, an entire chunk, or many chunks. Work needs to be done to re-assemble Sigv4 chunks after HTTP chunks are processed in the pipeline.


## Netty pipeline issues
The current Object Storage pipeline queues ChannelBuffers into an InputStream which is remoted to the backend service and consumed by the S3 client that is writing an object to the backend. The rate of consumption may not necessarily match the rate of inbound data to the input stream, which can cause OutOfMemoryErrors as well as other performance problems, eventually leading to file upload failures.

While an InputStream is not the ideal abstraction for moving file upload data through our pipeline to the backend to its ultimate storage location, ultimately we need to be able to apply backpressure to channel that is sending data if/when our ability to stream a file into the backend is constrained. Queuing data internally can be done on a limited basis to accomodate latency fluctuations, but backpressure is desirable over excessive queueing to control the flow of data through the pipeline.

Issues related to this work:
1. EUCA-12769
1. [EUCA-11464](https://eucalyptus.atlassian.net/browse/EUCA-11464)
1. EUCA-11320




# Elements

# Interactions

# Abstractions

# Milestones

## Sprint 1
Implement an initial spike of a Netty based S3 signature V4 supporting server.


## Sprint X

* Add Sigv4 validation for S3 read requests.
* Implement Sigv4 S3 chunk decoding.
* Add Sigv4 validation for initial S3 put request.
* Add Sigv4 validation for S3 put request chunks.
* Implement Netty channel backpressure for put data streams.


# Risks
Areas currently identified as risks:


* Will need regression testing to ensure that changes to current OSG pipeline are not breaking.
* If upgrading to Netty 4, ensure functional compatibility.
* Performance is not likely to decrease, but need to ensure that performance problems with data publish/consumption mismatches are resolved in the pipeline.


# References








*****

[[tag:confluence]]
[[tag:rls-4.4]]
[[tag:object-storage]]
