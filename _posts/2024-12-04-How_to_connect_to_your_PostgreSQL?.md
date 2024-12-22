---
title: How to connect to your PostgreSQL?
date: 2024-12-04 12:24:00 +0530
categories: [PostgreSQL, Practical]
tags: [postgresql, notes, practical]
toc: true
---

The post title might look like a clickbait but let me assure that this is not. Basically, there are engineers like me who only understand the theory by practically doing it. So in my [previous post](/posts/Configuration_Files_in_PostgreSQL), I discussed Configuration files in PostgreSQL and in this post I will guide how these configuration files plays a role in granting the access to the database cluster. The configuration files will be used are `postgresql.conf` and `pg_hba.conf`.

In this scenario, I will be using a bash script which will perform the connection and return the version of the PostgreSQL running on the target server. You can find the bash script [here](/assets/scripts/conn_psql.sh). Before attempting to connect, let's make sure that the PostgreSQL cluster is running on the server.

```shell
# Running on 192.168.1.105
$ pg_ctl status -D $PGDATA
pg_ctl: server is running (PID: 655)
/usr/lib/postgresql/14/bin/postgres "-D" "/var/lib/postgresql/14/main" "-c" "config_file=/etc/postgresql/14/main/postgresql.conf"
```

Now check if there is connectivity from my client server (`192.168.1.17`) to the PostgreSQL server (`192.168.1.105`).

```shell
$ ./conn_psql.sh 192.168.1.105 5432

--------------------------------
My IP Address is: 192.168.1.17
--------------------------------

-> Checking connectivity to 192.168.1.105...[FAILED]
```

If you get similar output like me then it means that the connectivity is not present, then you can check the `firewalld` or `iptables` service and disable them or ask your administrator to add a firewall rules. For testing purpose, I have disabled the firewall on both of the machines.

### Modify `postgresql.conf`

The reason I am getting the error is that the port on the PostgreSQL is running on `localhost` and not on `0.0.0.0`, so we will modify parameter `listen_addresses` in `postgresql.conf` file so that the connection is successful. To verify that you can make use of `netstat -tunlp` command which will show on which IP the port is attached to.

```shell
$ grep listen_addresses postgresql.conf
#listen_addresses = 'localhost'         # what IP address(es) to listen on;
$ vi postgresql.conf
$ grep listen_addresses postgresql.conf
listen_addresses = '*'          # what IP address(es) to listen on;
$ sudo systemctl restart postgresql
$ netstat -tunlp | grep -w 5432
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
tcp        0      0 0.0.0.0:5432            0.0.0.0:*               LISTEN      -
tcp6       0      0 :::5432                 :::*                    LISTEN      -
```

Now let's test the connection again with our bash script to see if it establishes or not:

```shell
$ ./conn_psql.sh 192.168.1.105 5432

--------------------------------
My IP Address is: 192.168.1.17
--------------------------------

-> Checking connectivity to 192.168.1.105...[PASSED]
-> Connecting to database on 192.168.1.105:5432...[FAILED]
---
psql: error: connection to server at "192.168.1.105", port 5432 failed: FATAL:  no pg_hba.conf entry for host "192.168.1.17", user "postgres", database "postgres", SSL encryption
connection to server at "192.168.1.105", port 5432 failed: FATAL:  no pg_hba.conf entry for host "192.168.1.17", user "postgres", database "postgres", no encryption
```

### Modify `pg_hba.conf`

Now that we are able to connect to the PostgreSQL server on the port 5432, but we end up with an error that there is no entry in `pg_hba.conf`, let's add an entry for our particular host with `md5` authentication method.

```shell
$ grep 192.168.1.17 pg_hba.conf
$ vi pg_hba.conf
$ grep 192.168.1.17 pg_hba.conf
host    postgres        postgres        192.168.1.17/32         md5
$ sudo systemctl restart postgresql
# We need to change the password else it will not allow
# to connect
$ psql
psql (14.15 (Ubuntu 14.15-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# alter user postgres with password 'secret123';
ALTER ROLE
```

With this added line we are instructing PostgreSQL server that allow connection to only `postgres` database for `postgres` user if the connection originates from `192.168.1.17`, and it will be authenticated using `md5` authentication method. Now let's run our bash script again, and this time it should return the version of the server.

> Please note that in production avoid using `md5` as authentication method because it uses a custom less secure challenge-response mechanism, the recommended is using `scram-sha-256` which is a challenge-response scheme that prevents password sniffing on untrusted connections and supports storing passwords on the server in a cryptographically hashed form that is thought to be secure. Read more in [documentation](https://www.postgresql.org/docs/current/auth-password.html).
{: .prompt-info }

```shell
$ ./conn_psql.sh 192.168.1.105 5432

--------------------------------
My IP Address is: 192.168.1.17
--------------------------------

-> Checking connectivity to 192.168.1.105...[PASSED]
-> Connecting to database on 192.168.1.105:5432...[PASSED]

                                                                version                                                                 
----------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 14.15 (Ubuntu 14.15-0ubuntu0.22.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit
(1 row)
```

It returned the version of the PostgreSQL database from a different server, which means all the settings we did in the configuration files worked.

### Conclusion

So in order to connect to a PostgreSQL cluster either from same server or a different server, the method used will be same that we would first need to change the [listen_addresses](https://postgresqlco.nf/doc/en/param/listen_addresses/) parameter to instruct cluster from which address the connection should be accepted, then we have to make an entry into `pg_hba.conf` file which instructs the cluster how the user should be authenticated and to which database he/she should connect to. For static parameter changes like `listen_addresses` we require a server restart and for `pg_hba.conf` changes reload should be enough. For more information on configuration files, I would recommend checking out my [previous post](/posts/Configuration_Files_in_PostgreSQL) and for more information on `pg_hba.conf` go through the [community documentation](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html).
