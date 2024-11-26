---
title: PostgreSQL Architecture
date: 2023-11-26 19:11:00 +0530
categories: [PostgreSQL, Notes]
tags: [postgresql, architecture]
---

In this post, we will go over PostgreSQL architecture, including Physical and Memory and how they interact with each other. Please consider this post as a basic and an overview of how PostgreSQL operates, if you require detailed information on the architecture, request you to go through the community documentation which has this information in detail. PostgreSQL is a relational database management system with a client-server architecture. At server side, the PostgreSQL's processes and shared memory will work together and build an instance/cluster, which will be handling the access to the data. Client programs connect to the instance/cluster and request read and write operations.

## Memory Architecture

![Memory Architecture](/assets/img/pg_memory_architecture.png){: w="350" h="350" }

As shown in above image, we can see that the memory architecture has 2 subareas:

- **Local Memory Area:** This is allocated per backend process, and can be accessed by that particular process only.
- **Shared Memory Area:** This memory area is used by all the processes in the PostgreSQL cluster.

We will discuss both of them now in detail, to understand how they are being used in a PostgreSQL cluster.

### Local Memory Area

When a backend process is started it allocates a local memory area for query processing and maintenance activities. This is again having several other components, which can either be fixed or variable.

- **work_mem:** The backend process will utilize this area when there is any sorting or table join operation to be performed. This can be configured using [work_mem](https://postgresqlco.nf/doc/en/param/work_mem/) parameter, the default value is 4096KB (4MB).
- **maintenance_work_mem:** This memory area is used for maintenance operations such as [REINDEX](https://www.postgresql.org/docs/current/sql-reindex.html), [VACUUM](https://www.postgresql.org/docs/current/sql-vacuum.html). This can be configured using [maintenance_work_mem](https://postgresqlco.nf/doc/en/param/maintenance_work_mem/), the default value is 64KB.
- **temp_buffers:** Temporary table will be stored in this memory area, and with the help of [temp_buffers](https://postgresqlco.nf/doc/en/param/temp_buffers/) parameter we can set the value.

### Shared Memory Area

This memory area get allocated when we start a PostgreSQL instance/cluster, and is accessible to all the processes. This memory area also has several other components with different usage.

- **Shared buffers:** This is the area of shared memory where the table/index pages will be loaded from the persistent storage for further operations. Configuration parameter is [shared_buffers](https://postgresqlco.nf/doc/en/param/shared_buffers/), default value is 16384 (128M).
- **WAL buffers:** This buffer holds WAL (_transactional logs_) data before it is written to the persistent area. This is to ensure that no data is lost in case of server failure or crash. Use [wal_buffers](https://postgresqlco.nf/doc/en/param/wal_buffers/) parameter to configure this area, default value is -1 which corresponds to around 3% of `shared_buffers`.
- **CLOG buffers:** It keeps the state of all transactions (e.g. In Progress, Committed or Aborted) for the concurrency control.

In addition to above, there are other buffers also allocated in shared memory area to store some useful information about the database, such as:

- A buffer is allocated to handle access control mechanisms (e.g. shared and exclusive locks, lightweight locks, etc.)
- Buffers for background processes like checkpointer and autovacuum 
- A buffer to keep track of transaction processing, such as savepoints and two-phase commit.

## Process Architecture

![Process Architecture](/assets/img/pg_process_architecture.png){: w="350" h="350"}

PostgreSQL is a client/server type relational database management system with a multiprocess architecture that runs on a single host. A collection of multiple processes that cooperatively manage a database cluster is usually referred to as a ‘PostgreSQL server’. It contains the following types of processes:

- **postgres (server process):** It is the parent process of all other processes related to database cluster management. When PostgreSQL instance start, this is the first process to get spawned, which also allocates the shared memory area and is also responsible for spawning other background processes and then waits for incoming connections. In older PostgreSQL versions, it was also called as **postmaster** process.
- **backend process (postgres):** When a client requests for connection, **postgres** (_previously postmaster_) will perform the authentication and once a successful authentication is completed, it will assign that client a background process which will handle all the queries which are issued by connected client. It communicates with the client using a single TCP connection and gets terminated when the client disconnects. When client tries to connect to PostgreSQL Cluster, it has to specify which database it has to connect to because a backend process is allowed to operate on one database at a time. PostgreSQL allows multiple clients to connect simultaneously, and we can set [max_processes](https://postgresqlco.nf/doc/en/param/max_processes/) parameter (default: 100) to control maximum number of clients that can connect to the database.
- **Background processes:** There are various background processes which are responsible for different tasks. Few other important background processes are:
    - **background writer:** This background process writes the dirty buffers from shared buffers to a persistent storage on regular basis. In versions 9.1 or earlier, this process was also responsible for the checkpointing. By default, background writer wakes every `200 ms` ([bgwriter_delay](https://postgresqlco.nf/doc/en/param/bgwriter_delay/)) and flushes 100 pages by default ([bgwriter_lru_maxpages](https://postgresqlco.nf/doc/en/param/bgwriter_lru_maxpages/)) at most.
    - **checkpointer:** This process will write a checkpoint record to the WAL segment file and flushes dirty pages whenever checkpointing starts. There will be full page write ([full_page_writes](https://postgresqlco.nf/doc/en/param/full_page_writes/)) which is enabled by default, for the first modification of any page post checkpoint, this is to avoid any data corruption due to OS crash. Below are the reasons when we can expect a checkpoint can occur:
        - Interval time specified in [checkpoint_timeout](https://postgresqlco.nf/doc/en/param/checkpoint_timeout/) (default: 5min) from last checkpoint has been elapsed.
        - The total size of the WAL segment files in `pg_xlog` directory has exceeded the value specified in [max_wal_size](https://postgresqlco.nf/doc/en/param/max_wal_size/) parameter (default: 1G / 64 files). This is a soft limit and database will try not to exceed this value, but it is allowed to.
        - PostgreSQL server is stopped in either smart or fast mode.
        - Superuser issues [CHECKPOINT](https://www.postgresql.org/docs/current/sql-checkpoint.html) command manually. 
    - **autovacuum launcher:** Responsible for periodically invoking autovacuum worker process to perform vacuum. By default, it wakes every 1 minute ([autovacuum_naptime](https://postgresqlco.nf/doc/en/param/autovacuum_naptime/)) and invokes 3 workers ([autovacuum_max_workers](https://postgresqlco.nf/doc/en/param/autovacuum_max_workers/)).
    - **WAL writer:** Writes WAL data from WAL buffers to persistent storage periodically, the file is usually called as WAL file. This is enabled by default, and we cannot disable this process. By default, it will check every `200 ms` ([wal_writer_delay](https://postgresqlco.nf/doc/en/param/wal_writer_delay/)) to see if there is data in buffers which is to be flushed.
    - **WAL Summarizer:** This background process is introduced in PostgreSQL 17 to support incremental backups. It will track changes to all database blocks and write these modifications to WAL summary files located in `pg_wal/summaries` directory.
    - **statistics collector:** As the name suggests, it collects statistics information and stores in pg_stat_activity and pg_stat_database, etc. (This process is deprecated in PostgreSQL 15 onwards)
    - **logger/logging collector:** Responsible for writing error message and logging details if logging is enabled, this gets recorded in log file (`postgresql.log`)
    - **archiver:** Executes archiving of WAL log files. Copies WAL segments to an archival area at the time when a WAL segment switch occurs. The path to archival area is set by the [archive_command](https://postgresqlco.nf/doc/en/param/archive_command/) configuration parameter.
    - **wal sender:** Runs on a primary server, sends WAL data to standby server.
    - **wal receiver:** Runs on secondary server, receives and replays the WAL data.
    - **logical replication launcher:** Launches logical replication workers for every enabled subscription.
