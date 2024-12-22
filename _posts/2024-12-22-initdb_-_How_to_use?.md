---
title: initdb - How to use?
date: 2024-12-04 15:15:00 +0530
categories: [PostgreSQL, Utilities & Extensions]
tags: [postgresql, notes, utilities, extensions]
toc: true
---

In my previous post about PostgreSQL software installation ([Source code installation](/posts/PostgreSQL_Installation/#source-code-installation)), I used a command called `initdb` to create a database cluster. In this post, I'll try to go a dive deeper into some of the options that can be used in real world, so that creation of cluster can be tailored to our specific needs.

As per the [official documentation](https://www.postgresql.org/docs/current/app-initdb.html), the main purpose of this utility is to create a new PostgreSQL database cluster. In the package installation, the command is automatically run which takes the default values to create the database cluster but if we want to customize the PostgreSQL database cluster then we have to make use of this command/utility.

## initdb

When you invoke a `initdb` utility, it creates a database cluster which consists of following operations:

- Creating directories in which cluster data will be present. (_There will be a dedicated post discussing the directories of PostgreSQL cluster in later post_)
- Generating the shared catalog tables (tables that belong to the whole cluster rather than to any particular database)
- Creating the `postgres`, `template1`, and `template0` databases.
  `postgres` database is the default database meant for use by users, utilities and third party applications. `template1` and `template0` are template databases, and when a user issues `CREATE DATABASE` command, it will be copy of the `template1` database. `template0` should never be modified, but you can add objects to template1, which by default will be copied into databases created later.

`initdb` must be run as the user that will own the server process, because the server needs to have access to the files and directories that `initdb` creates.

There are several options that can be coupled with this command, but in this post I will discuss few of the useful ones. I will also share some examples which you can use to understand the utility further.

## Options

### Data directory

Using `-D` or `--pgdata` option we can specify the data directory where the database cluster will be stored. This is a **mandatory** option to run the `initdb` command, but we can set `PGDATA` environmental variable to avoid using this option. This is because if we do not specify the option `-D`, it will look for the environmental variable first and if it does not found one then the command will fail with below error:

```shell
$ initdb
initdb: error: no data directory specified
You must identify the directory where the data for this database system
will reside.  Do this with either the invocation option -D or the
environment variable PGDATA.
```

### Group Read access for cluster files

With option `-g` or `--allow-group-access`, we can control whether users within same group can read the cluster files created by `initdb` command, this will include all the configuration files as well. This will be useful when we want to take a backup of the cluster from a non-privileged user.

### Bootstrap Superuser

[Bootstrap superuser](https://www.postgresql.org/docs/current/glossary.html#GLOSSARY-BOOTSTRAP-SUPERUSER) is the first user initialized in the database cluster and owns all the catalog tables in each database. This role can also behave like a normal [database superuser](https://www.postgresql.org/docs/current/glossary.html#GLOSSARY-DATABASE-SUPERUSER), but its superuser status cannot be removed. So the options associated with are:

- `-U` or `--username`: Sets the name of the bootstrap superuser.
- `-W` or `--pwpromt`: Asks for password for the bootstrap superuser.
- `--pwfile`: Password for the bootstrap superuser, `initdb` will consider first line as password.

### WAL configuration

- **Directory configuration:** If you want to use a separate disk or mount point to hold the WAL (Write-Ahead-Logs) files for the PostgreSQL database cluster then you can specify the location with `-X` or `--waldir` option.
- **Segment size configuration:** There will be scenarios where you may want to set the size of individual files in the WAL log, then you can use `--wal-segsize` option. Please note that the default is 16 megabytes and value you specify will be in megabytes. This cannot be modified post creation of database cluster, this value can only be modified during the initialization of the cluster.

> In my day-to-day use, I have not seen most of the customer customizing the *locale* of the databse but there are several options with which you can set the *locale*, if I came across any example with *locale* being used, I will surely update this post with the link. If you are interested then I would suggest review the official documentations[[1]](https://www.postgresql.org/docs/current/app-initdb.html)[[2]](https://www.postgresql.org/docs/current/locale.html) for the same.
{: .prompt-info }

## Examples

1. Vanilla database cluster initiation.
   ```shell
   $ initdb -D '/path/to/datadirectory'
   ```
   OR
   ```shell
   $ export PGDATA='/path/to/datadirectory'
   $ initdb
   ```
2. Use a different bootstrap user other than `postgres`
   *Getting password from the prompt.*
   ```shell
   $ export PGDATA='/path/to/datadirectory'
   $ initdb -U pgadmin -W
   ```
   *Providing the password with password file.*
   ```shell
   $ export PGDATA='/path/to/datadirectory'
   $ echo "secretpassword" | tee ~/.pwfile
   $ initdb -U pgadmin --pwfile ~/.pwfile
   ```
3. Store WALs at a different location than data directory
   ```shell
   $ initdb -D /path/to/datadirectory -X /path/to/walfiles
   ```
4. Changing the size of the segment files in WAL logs
   ```shell
   # changes default size from 16mb to 32mb
   $ initdb -D /path/to/datadirectory --wal-segsize 32
   ```

You can even combine all of these settings into one, I would recommend doing your own testing with these. As always if you have any doubts please reach out to me via [LinkedIn](https://www.linkedin.com/in/akgirme) or via mail.
