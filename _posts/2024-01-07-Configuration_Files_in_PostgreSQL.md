---
title: Configuration Files in PostgreSQL
date: 2024-01-07 12:24:00 +0530
categories: [PostgreSQL, Notes]
tags: [postgresql, notes]
toc: true
---

In PostgreSQL there are several configuration files which are used to configure the cluster work in certain way. Using these configuration files, we can administer our PostgreSQL cluster. In this post, I will discuss essential configuration files.

## Configuration Files

The default location of these configuration files is under the data directory of the cluster but as seen in our previous post ([Installation of PostgreSQL server](/posts/PostgreSQL_Installation/#package-installation)) that these locations can vary depending upon the method you choose to install. You can easily get the location of these files by querying [pg_settings](https://www.postgresql.org/docs/current/view-pg-settings.html) or [pg_file_settings](https://www.postgresql.org/docs/current/view-pg-file-settings.html) table.

_Below is a snippet of how I usually get the locations of the files, I am using PostgreSQL 14.15 running on Ubuntu_
```shell
postgres=# SELECT DISTINCT
postgres-#   substr(setting, 0, (length(setting) - strpos(reverse(setting), '/')) + 1) AS conf_path
postgres-# FROM pg_settings WHERE setting LIKE '%conf';
        conf_path
-------------------------
 /etc/postgresql/14/main
(1 row)
```

Now that we have the path lets list it to get the files that will be discussed in this post::

```shell
$ ls -ltr /etc/postgresql/14/main/*.conf
-rw-r--r-- 1 postgres postgres   317 Jan  4 13:06 /etc/postgresql/14/main/start.conf
-rw-r--r-- 1 postgres postgres   143 Jan  4 13:06 /etc/postgresql/14/main/pg_ctl.conf
-rw-r----- 1 postgres postgres  1636 Jan  4 13:06 /etc/postgresql/14/main/pg_ident.conf
-rw-r----- 1 postgres postgres  5002 Jan  4 13:06 /etc/postgresql/14/main/pg_hba.conf
-rw-r--r-- 1 postgres postgres 29024 Jan  4 13:06 /etc/postgresql/14/main/postgresql.conf
```

### start.conf

This is available when we perform a package installation, as it will be used to control if the cluster should be started automatically (`auto`), manually (`manual`) or should not be started (`disabled`). The file basically contains the configuration for automatic startup. This file only contains the configuration values (i.e. `auto`, `manual` or `disabled`). If you change the configuration then you would need to invoke `sudo systemctl daemon-reload` command, so that the changes take effect.

### pg_ctl.conf

This file will contain the [pg_ctl options](https://www.postgresql.org/docs/current/app-pg-ctl.html) which will be cluster specific. The file looks something like below:

```shell
$ cat /etc/postgresql/14/main/pg_ctl.conf
# Automatic pg_ctl configuration
# This configuration file contains cluster specific options to be passed to
# pg_ctl(1).

pg_ctl_options = ''
```

### pg_ident.conf

This file controls PostgreSQL username mapping, it maps external usernames to their corresponding PostgreSQL usernames. Records are of the form:

|**MAPNAME**|**SYSTEM-USERNAME**|**PG-USERNAME**|

For more information about this file, I would suggest reading more on [PostgreSQL documentation](https://www.postgresql.org/docs/17/auth-username-maps.html).

### pg_hba.conf

This is one of the most important configuration file which will be used most of the time in Production to control the access to the PostgreSQL cluster. It is a **H**ost **B**ased **A**uthentication file, which has the information about how a user will be authenticated or rejected. The format of this file is a set of records, one per line. Blank lines and comments (lines after #) are ignored.

Records present in this file will decide which hosts are allowed or not allowed to connect, how clients are authenticated, which PostgreSQL users can connect and to which database they have access to. A sample record in this file would look something like:

|**TYPE**|**DATABASE**|**USER**|**ADDRESS**|**METHOD**|


- TYPE: This defines if a user is local or remote, using local for local users and host for remote users. The host value includes both SSL-encrypted and non-SSL connections. 
- DATABASE: Specifies database name(s) to which the users will be allowed/rejected to connect. The values are all, a specific database or list of databases separated by commas or replication. The replication value will come in effect if the connection requests for a physical replication, this is for replicating data from one database to another.
- USERNAME: Can be all, a username, a group name prefixed with "+" or a comma-separated list of users.
- ADDRESS: Specifies hostnames, IP addresses or an IP CIDR blocks from which the connection is allowed/rejected.
- METHOD: Specifies how the client will be authenticated.
    - `trust`: Allows connection without password. Most dangerous, do not use this in PROD.
    - `reject`: Straightaway, reject even if the credentials are valid. This can be used to filter out certain users or certain hosts.
    - `scram-sha-256`: Perform scram-sha-256 authentication to verify user's password.
    - `md5`: Perform scram-sha-256 or md5 authentication to verify the user's password.

For more information about this file, please check [community documentation](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html).

### postgresql.conf

The primary source of configuration parameter settings of a PostgreSQL cluster will be present in this file. This file is read on server startup and when server receives a `SIGHUP` (RELOAD) signal. If changes are made to this file when the cluster is running, then you either have to run `pg_ctl reload` or execute `SELECT pg_reload_conf()`. There are some static parameters which require a server shutdown or restart to take effect.

All the parameters that can be configured using this file are present in the file, which is to represent the default values, but they are commented-out. From versions 12+, there is another file called `postgresql.auto.conf` which stores the parameter changes made via `ALTER SYSTEM` command. This file is managed by PostgreSQL cluster itself and there should not be any manual changes made to this file. This file is read at the end, so configuration settings present in this file will always override settings in other files.

The `ALTER SYSTEM` command can only be executed by a superuser. Later in PostgreSQL 15, permissions to alter individual configuration parameters can be granted to the non-superusers. The value of the configuration parameter which will be modified by `ALTER SYSTEM` command should be enclosed in single quotes, otherwise the value of that parameter will be reset to DEFAULT and the entry for that parameter will be removed from `postgresql.auto.conf` file.

## Conclusion

In this post, I discussed several configuration files and there are few which are important and will be required for you to edit them once in a month and those are - `pg_hba.conf` and `postgresql.conf`, apart from these, I have not seen other configuration files getting modified often.
