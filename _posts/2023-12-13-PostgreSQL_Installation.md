---
title: Installation of PostgreSQL server
date: 2023-12-13 23:53:00 +0530
categories: [PostgreSQL, Notes]
tags: [postgresql, installation]
toc: true
---

In this post we will go over two methods of installing a PostgreSQL server. Both of the methods have their pros and cons, so I will also try to go over those. I will be using RHEL (Red Hat Enterprise Linux) and Ubuntu because most of the servers are either running these operating systems or an operating system which is a flavor of them. Reason for not including Windows is, as per my experience there is very rare scenario where some organization will go for installation of a PostgreSQL on Windows.

# Versioning

Before installation, we will first understand how PostgreSQL versioning works.

PostgreSQL database has a Major version and Minor version. The major version comes with new features and is released at least once a year. The minor version includes bug fixes or security fixes and are released every three months. Starting PostgreSQL 10, the major version is indicated by increasing the first part of the version, e.g. 10 to 11, and minor releases are numbered by increasing the last part of the version, e.g. 10.0 to 10.1.

# Installation Methods

> Warning: Do NOT Perform These Actions in Production! ⚠️ The following content is intended for educational purposes only. Performing these actions in a production environment may lead to data loss, system downtime, or other severe consequences. Proceed with caution and ensure all actions are tested in a non-production environment first.
{: .prompt-danger }

There are two ways you can install a PostgreSQL database, either by building the source code (**Source Code Installation**) or by installing through a package manager (**Package Installation**). The only difference in both of them according to me is that in [Source Code Installation](#source-code-installation), you have total control of how you want to configure your installation whereas with [Package Installation](#package-installation) it will have all the things bundled. When we go into them, you will understand better what I meant by _all the things bundled_.

## Package Installation

In my opinion, this is the simplest method to install the PostgreSQL database server, because we would need to only run few commands for installation. Because in the all the things which we would have to do manually in Source Code installation. You would need to follow below steps to install a PostgreSQL.

### Ubuntu

```shell
# Use below command to install PostgreSQL
# included in the distribution
$ sudo apt-get install postgresql -y

# Use below to configure the repostiory automatically
$ sudo apt install -y postgresql-common
$ sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Use below command to install the latest minor version any Major version of Postgresql.
# Basically below will install the latest minor version of PostgreSQL 14.
$ sudo apt install postgresql-14 -y
```

By following above commands, you will automatically fulfill the prerequisites which are required for the installation (_as these will be taken care by the package manager in this case `apt`_) and you will also have a cluster up and ready. In Ubuntu, below are the default locations:

- **Installed software:** `/usr/lib/postgresql/<MajorVersion>`
- **Data directory:** `/var/lib/postgresql/<MajorVersion>/main`
- **Configuration Files:** `/etc/postgresql/<MajorVersion>/main`

### RHEL (Red Hat Enterprise Linux)

For this setting up the repository is a little different from the one which we used in the Ubuntu. Here we have to install the repository for specific version instead of above automated one. Go to [PostgreSQL Yum Repository](https://www.postgresql.org/download/linux/redhat/) website and select the version, and it will present you with the steps. I have chosen below and below is the script that I have executed to install PostgreSQL.

**Options**
- Select version: 14
- Select platform: Red Hat Enterprise, CentOS, Scientific or Oracle Linux 8
- Select architecture: x86_64

```shell
# Install the repository RPM:
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Disable the built-in PostgreSQL module:
sudo dnf -qy module disable postgresql

# Install PostgreSQL:
sudo dnf install -y postgresql14-server

# Optionally initialize the database and enable automatic start:
sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
sudo systemctl enable postgresql-14
sudo systemctl start postgresql-14
```

> While following above if you get error `Error: Failed to download metadata for repo 'pgdg-common': repomd.xml GPG signature verification error: Bad GPG signature` then remove the file `/etc/yum.repos.d/pgdg-redhat-all.repo` then perform an update of the repos and try the process again.
{: .prompt-info }

In Red Hat Enterprise Linux, the default locations will be:

- **Installed software:** `/usr/lib/postgresql/<MajorVersion>`
- **Data directory:** `/var/lib/postgresql/<MajorVersion>/main`
- **Configuration Files:** `/etc/postgresql/<MajorVersion>/main`

## Source Code Installation

This is not that simple compare to [Package Installation](#package-installation), as here we have to complete all the steps by ourselves. Before we begin with this, I would suggest you to grab a Coffee/Tea ☕ because this is going to be a very long section of this post.

### Prerequisites

#### Ubuntu

```shell
# Install required packages
#   - wget: To download a file from internet
#   - gcc: This is compiler for C language (PostgreSQL is developed in C)
#   - zlib1g & zlib1g-dev: Required for implementing compression
#   - readline, readline-devel & libreadline-dev: These are helpful for commands we run in psql, we can go back and edit.
$ sudo apt install wget gcc make zlib1g zlib1g-dev readline* libreadline-dev -y
```

#### Red Hat Enterprise Linux (RHEL)

```shell
# Install required packages
#   - wget: To download a file from internet
#   - gcc: This is compiler for C language (PostgreSQL is developed in C)
#   - zlib: Required for implementing compression
#   - readline, readline-devel & libreadline-dev: These are helpful for commands we run in psql, we can go back and edit.
$ sudo dnf install -y wget gcc make zlib readline readline-devel
```

### Installation

These steps are similar for any distro, so I will not segregate them, instead I will just mention what is the purpose of that step. To get the link of the PostgreSQL source code, go to [PostgreSQL Community](https://www.postgresql.org/ftp/source/) website ⇾ Select the version that you want to install ⇾ Right-click on the `postgresql-<MajorVersion>.<MinorVersion>.tar.gz` file and copy link address. You can also download it on your machine/laptop and then transfer it to the server.

```shell
# I am installing 13.7 so I went through above steps and got the link
$ wget https://ftp.postgresql.org/pub/source/v13.7/postgresql-13.7.tar.gz

# It will download the tar ball, extract it
$ tar -xvf postgresql-13.7.tar.gz
```

> It may inform you that the connection to ftp.postgresql.org is not secure as it is unable to verify the certificate and if you want to connect use `--no-check-certificate`. So just append `--no-check-certificate` to the end of the `wget` command.
{: .prompt-info }

Once the `tar` command decompresses the downloaded tar ball, it will create folder which will hold all the source of the particular version (_In this case source code of 13.7_). So now we will move ahead with further steps:

#### Configure the source tree using `configure` script which comes with source code.

```shell
# I want to install the PostgreSQL 13.7 into /usr/local/pgsql13.7/
# location so I will first create it
$ sudo mkdir -p /usr/local/pgsql13.7/

# Make sure that you are in the directory where we just decompressed
# the source code in order to run this command. We have to then
# pass this as an option to the configure command.
$ sudo ./configure --prefix /usr/local/pgsql13.7/

# Verify that the configuration is success by checking the
# status of the command. Output should return 0
$ echo $?

# You can also check the last 4 lines of config.log
# It will contain the version that you are installing and the status
# Last line of this must be `exit 0`
$ tail config.log
#define PG_VERSION_STR "PostgreSQL 13.7 on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit"
#define PG_VERSION_NUM 130007

configure: exit 0
```

> You may get error like `Use --without-readline to disable readline support.`, if you get this error then you would have to install the correct library or use the `--without-` option with `configure` command.
{: .prompt-info }

Below are some of the options I think might be useful, so I have only included them. If you want to have the full list of the option, make sure to check [PostgreSQL official documentation](https://www.postgresql.org/docs/current/install-make.html#CONFIGURE-OPTIONS) or you can also get the list using `./configure --help`.

- `--prefix`: Installation will be done in the specified location, instead of the default location (`/usr/local/pgsql`)
- `--with-pgport`: Changes the default port from 5432 to the specified _Number_.
- `--with-openssl`: Builds the source tree with support SSL connections. 

#### Build the source tree using `make` command.

```shell
$ sudo make world-bin
```

There are different options that you can use with the `make` command, which is designed for building the PostgreSQL software differently. Below are the options and how it will be built in a single line, for more information check the `INSTALL` file from the source code or [documentation](https://www.postgresql.org/docs/current/install-make.html#INSTALL-PROCEDURE-MAKE).

- `make world`: To build everything including documentation (HTML and `man` pages) and additional modules (`contrib`).
- `make world-bin`: It will build with additional modules (`contrib`) but it will exclude the documentation (HTML and `man` pages)

#### Installation of the software using `make install` command

```shell
# Install the software
$ sudo make install-world-bin

# Verify if it is installed correctly
$ /usr/local/pgsql13.7/bin/psql --version
psql (PostgreSQL) 13.7
```

> Choose the appropriate install option, if you have used `world` while building then use `install-world`
{: .prompt-info }

#### Create and setup `postgres` user

**Create the user and assign appropriate permissions to the user**

```shell
# Create postgres user
$ sudo useradd postgres -c "PostgreSQL Linux User"
$ mkdir /home/postgres

# Set password for the user
$ sudo passwd postgres
New password:
Retype new password:
passwd: password updated successfully

# Provide permissions to postgres user on directories
$ sudo chown -R postgres:postgres /usr/local/pgsql13.7/
$ sudo chown postgres:postgres /home/postgres
```

**Setup the `.bash_profile` or equivalent profile of the user**

```shell
# Append below environmental variables to the .bash_profile
$ echo "export PATH=$PATH:/usr/local/pgsql13.7/bin/" >> ~/.bash_profile
$ echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/pgsql13.7/lib"  >> ~/.bash_profile
$ echo "export DATADIR=/home/postgres/data/" >> ~/.bash_profile

# Source it
$ $SHELL -l

# Verify if it is correct
$ psql --version
```

#### Create the database using `postgres` user

```shell
# Create database using below command
$ initdb -D $DATADIR

# Start the database using below command
$ pg_ctl -D /home/postgres/data -l logfile start
waiting for server to start.... done
server started

# Verify by logging in
$ psql
psql (13.7)
Type "help" for help.

postgres=# select version();
                                                version
-------------------------------------------------------------------------------------------------------
 PostgreSQL 13.7 on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit
(1 row)

postgres=# 
```

#### Service creation

Now our installation and database initialization is complete, but when you reboot the server, the PostgreSQL will not come up automatically. For this we would need to create a service in the operating system which will make sure that the database is started if there is any crash or reboot. You can skip this part, but then you would have to make sure that you are starting the database manually.

To avoid that, we will create a new service called `postgresql-137`, which will make sure that our PostgreSQL service comes up automatically if machine reboots. Depending upon system that you are using the method might be different but a simple Google search will guide you. There are some scripts present in source code which we downloaded in [Installation](#installation), the location is `contrib/start-scripts`.

```shell
$ pwd
/home/akgirme/postgresql-13.7/contrib/start-scripts
$ ls -ltr
total 12
-rw-r--r-- 1 akgirme akgirme 3552 May  9  2022 linux
-rw-r--r-- 1 akgirme akgirme 1467 May  9  2022 freebsd
drwxrwxr-x 2 akgirme akgirme 4096 May  9  2022 macos

# Copy the file to make changes, changes are required as
# we have modified installation path and datadir
$ cp linux postgresql-137 

# Make below changes in the coped postgresql137 file
$ diff -y linux postgresql-137 --suppress-common-lines
prefix=/usr/local/pgsql                                       | prefix=/usr/local/pgsql13.7/
PGDATA="/usr/local/pgsql/data"                                | PGDATA="/home/postgres/data"

# In order for this to work we have to add below lines at the start
# and after #! /bin/sh
$ head -12 postgresql-137
#! /bin/sh

### BEGIN INIT INFO
# Provides:             postgresql
# Required-Start:       $local_fs $remote_fs $network $time
# Required-Stop:        $local_fs $remote_fs $network $time
# Should-Start:         $syslog
# Should-Stop:          $syslog
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    PostgreSQL RDBMS server
### END INIT INFO
$

# Copy the file to /etc/init.d and provide execute permission
$ sudo cp /home/akgirme/postgresql-13.7/contrib/start-scripts/postgresql-137 /etc/init.d/
$ sudo chmod +x /etc/init.d/postgresql-137

# Test the script to see if this works or not
$ ps -ef | grep postgres
akgirme     1604     767  0 05:14 pts/0    00:00:00 grep --color=auto postgres
$ sudo /etc/init.d/postgresql-137 start
Starting PostgreSQL: ok
$ ps -ef | grep postgres
postgres    1614       1  0 05:14 ?        00:00:00 /usr/local/pgsql13.7//bin/postmaster -D /home/postgres/data
postgres    1616    1614  0 05:14 ?        00:00:00 postgres: checkpointer
postgres    1617    1614  0 05:14 ?        00:00:00 postgres: background writer
postgres    1618    1614  0 05:14 ?        00:00:00 postgres: walwriter
postgres    1619    1614  0 05:14 ?        00:00:00 postgres: autovacuum launcher
postgres    1620    1614  0 05:14 ?        00:00:00 postgres: stats collector
postgres    1621    1614  0 05:14 ?        00:00:00 postgres: logical replication launcher
akgirme     1623     767  0 05:14 pts/0    00:00:00 grep --color=auto postgres
$ sudo /etc/init.d/postgresql-137 stop
Stopping PostgreSQL: ok
$ ps -ef | grep postgres
akgirme     1636     767  0 05:15 pts/0    00:00:00 grep --color=auto postgres
$ sudo /etc/init.d/postgresql-137 status
pg_ctl: no server running

# Enable the service so that post reboot and reload the daemon
# so that the new service will reflect
$ sudo systemctl enable postgresql-137
postgresql-137.service is not a native service, redirecting to systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable postgresql-137
$ sudo systemctl daemon-reload
$ sudo systemctl status postgresql-137
○ postgresql-137.service - LSB: PostgreSQL RDBMS server
     Loaded: loaded (/etc/init.d/postgresql-137; generated)
     Active: inactive (dead)
       Docs: man:systemd-sysv-generator(8)
```

> There is wrapper for [Source Code Installation](#source-code-installation), which is called [pgenv](https://github.com/theory/pgenv). Using this it makes the installation easier for you to install any available PostgreSQL version with just few commands. There is customization in that as well but if it is covered in this post then it will become much longer post, so I avoided that. Go through the [documentation](https://github.com/theory/pgenv) to know more about it.
{: .prompt-tip }

# Conclusion

In real-time, mostly the database administrators will prefer going with package installation where almost everything is automatically handled. Source code installation will only be preferred in scenarios where there is no repository in PostgreSQL community website or there any special requirements by the clients, like having a custom directory or create different locations for minor versions as well. The major difference between Package Installation and Source Code Installation is that Source Code installation, allows you to customize the installation.

I can think of a use case where if I want to run multiple versions (13.10 & 13.7) of same major versions, with this I can do that on a single machine. Package installation will not allow that.
