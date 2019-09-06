# Online IDE Manager

This subdirectory contains code for the workspace/authentication
manager portion of the WWU CS online IDE system.  This is an
[Openresty](https://openresty.org/) application comprised of the
following:

* An [NGINX](https://nginx.org/) configuration file in the `conf`
directory which defines the application routes
* HTML, CSS, and image files and templates in the `html` directory
which help resolve some of those routes
* [Lua](https://www.lua.org/) programs that help resolve application
routes.


## Requirements

This application requres the following software to run:

* Base Ubuntu image configured to allow LDAP logins and automount user
homedirectories in /mnt/home
* The [Docker](https://docker.com/) container management engine, which can be 
installed via the `docker.io` package in Ubuntu
* The [OpenResty](https://openresty.org/) web applicaton platform, which can 
be installed via the `openresty` package in Ubuntu
* The [Redis](https://redis.io) in-memory data structure store, which
can be installed via the `redis-server` package in Ubuntu
* The [Lua-LDAP](https://github.com/lualdap/lualdap) LUA library which
encapsulates a Lua interface to LDAP servers.  This can be installed
via the `lua-ldap` packate in Ubuntu
* Two OpenResty modules:
** lua-resty-http for making http requests, which can be installed via
`opm ledgetech/lua-resty-http`
** lua-resty-template for dynamic html templates, which can be
installed via `opm bungle/lua-resty-template`


## Installation

Start with a base install of Ubuntu, configured for LDAP logins.

1. Install the automount system and create home directory mount point.

```bash
$ sudo apt-get install -y autofs
$ sudo mkdir /mnt/home
```
Then edit configuration files with your favorite editor so that the
`/etc/auto.master` file has only the following uncommented line:

```
/mnt/home /etc/auto.home
```

and the `/etc/auto.home` file contains only the following line:

```
* -rw,noserverino    data.cs.wallawalla.edu:/mnt/CSMain/home/&
```

Finally, reload the autofs confirugration:

```bash
$ sudo service autofs reload
```


2. Install the Docker container management engine.

Get the GPG key for the official Docker repository:

```bash
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

Add the Docker repository

```bash
$ sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
```

Update the package database with the Docker packages from this repository

```bash
$ sudo apt update
```

Then install the Docker program

```bash
$ sudo apt-get install -y docker-ce
```

Next, instruct the docker engine to listen on an internal TCP port by
creating the file `/etc/systemd/system/docker.service.d/override.conf` with the following content:

```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:8101
```

Reload the daemon files and restart the docker service:

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker.service
```

3. 
