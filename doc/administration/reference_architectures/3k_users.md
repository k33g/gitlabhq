# Reference architecture: up to 3,000 users

This page describes GitLab reference architecture for up to 3,000 users.
For a full list of reference architectures, see
[Available reference architectures](index.md#available-reference-architectures).

NOTE: **Note:** The 3,000-user reference architecture documented below is
designed to help your organization achieve a highly-available GitLab deployment.
If you do not have the expertise or need to maintain a highly-available
environment, you can have a simpler and less costly-to-operate environment by
following the [2,000-user reference architecture](2k_users.md).

> - **Supported users (approximate):** 3,000
> - **High Availability:** True
> - **Test RPS rates:** API: 60 RPS, Web: 6 RPS, Git: 6 RPS

| Service                                                      | Nodes | Configuration ([8](#footnotes)) | GCP           | AWS                   | Azure          |
|--------------------------------------------------------------|-------|---------------------------------|---------------|-----------------------|----------------|
| GitLab Rails ([1](#footnotes))                               | 3     | 8 vCPU, 7.2GB Memory            | n1-highcpu-8  | c5.2xlarge            | F8s v2         |
| PostgreSQL                                                   | 3     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large              | D2s v3         |
| PgBouncer                                                    | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large              | F2s v2         |
| Gitaly ([2](#footnotes)) ([5](#footnotes)) ([7](#footnotes)) | X     | 4 vCPU, 15GB Memory             | n1-standard-4 | m5.xlarge             | D4s v3         |
| Redis ([3](#footnotes))                                      | 3     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large              | D2s v3         |
| Consul + Sentinel ([3](#footnotes))                          | 3     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large              | F2s v2         |
| Sidekiq                                                      | 4     | 2 vCPU, 7.5GB Memory            | n1-standard-2 | m5.large              | D2s v3         |
| Object Storage ([4](#footnotes))                             | -     | -                               | -             | -                     | -              |
| NFS Server ([5](#footnotes)) ([7](#footnotes))               | 1     | 4 vCPU, 3.6GB Memory            | n1-highcpu-4  | c5.xlarge             | F4s v2         |
| Monitoring node                                              | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large              | F2s v2         |
| External load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large              | F2s v2         |
| Internal load balancing node ([6](#footnotes))               | 1     | 2 vCPU, 1.8GB Memory            | n1-highcpu-2  | c5.large              | F2s v2         |

## Footnotes

1. In our architectures we run each GitLab Rails node using the Puma webserver
   and have its number of workers set to 90% of available CPUs along with four threads. For
   nodes that are running Rails with other components the worker value should be reduced
   accordingly where we've found 50% achieves a good balance but this is dependent
   on workload.

1. Gitaly node requirements are dependent on customer data, specifically the number of
   projects and their sizes. We recommend two nodes as an absolute minimum for HA environments
   and at least four nodes should be used when supporting 50,000 or more users.
   We also recommend that each Gitaly node should store no more than 5TB of data
   and have the number of [`gitaly-ruby` workers](../gitaly/index.md#gitaly-ruby)
   set to 20% of available CPUs. Additional nodes should be considered in conjunction
   with a review of expected data size and spread based on the recommendations above.

1. Recommended Redis setup differs depending on the size of the architecture.
   For smaller architectures (less than 3,000 users) a single instance should suffice.
   For medium sized installs (3,000 - 5,000) we suggest one Redis cluster for all
   classes and that Redis Sentinel is hosted alongside Consul.
   For larger architectures (10,000 users or more) we suggest running a separate
   [Redis Cluster](../high_availability/redis.md#running-multiple-redis-clusters) for the Cache class
   and another for the Queues and Shared State classes respectively. We also recommend
   that you run the Redis Sentinel clusters separately for each Redis Cluster.

1. For data objects such as LFS, Uploads, Artifacts, etc. We recommend an [Object Storage service](../object_storage.md)
   over NFS where possible, due to better performance and availability.

1. NFS can be used as an alternative for both repository data (replacing Gitaly) and
   object storage but this isn't typically recommended for performance reasons. Note however it is required for
   [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/196).

1. Our architectures have been tested and validated with [HAProxy](https://www.haproxy.org/)
   as the load balancer. Although other load balancers with similar feature sets
   could also be used, those load balancers have not been validated.

1. We strongly recommend that any Gitaly or NFS nodes be set up with SSD disks over
   HDD with a throughput of at least 8,000 IOPS for read operations and 2,000 IOPS for write
   as these components have heavy I/O. These IOPS values are recommended only as a starter
   as with time they may be adjusted higher or lower depending on the scale of your
   environment's workload. If you're running the environment on a Cloud provider
   you may need to refer to their documentation on how configure IOPS correctly.

1. The architectures were built and tested with the [Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
   CPU platform on GCP. On different hardware you may find that adjustments, either lower
   or higher, are required for your CPU or Node counts accordingly. For more information, a
   [Sysbench](https://github.com/akopytov/sysbench) benchmark of the CPU can be found
   [here](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks).
