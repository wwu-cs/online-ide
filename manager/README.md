# Online IDE Manager

This sub-directory contains code for the workspace/authentication
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

This application requires the following software to run:

* Base Ubuntu image configured to allow LDAP logins and auto-mount user
home directories in /mnt/home
* The [Docker](https://docker.com/) container management engine
* The [OpenResty](https://openresty.org/) web application platform
* The [Redis](https://redis.io) in-memory data structure store
* The [Lua-LDAP](https://github.com/lualdap/lualdap) Lua library which
encapsulates a Lua interface to LDAP servers
* Two OpenResty modules:
** lua-resty-http for making http requests, and
** lua-resty-template for dynamic html templates


## Installation

Start with a base install of Ubuntu, configured for LDAP logins and
follow the steps below.


### This Repository

First, clone this repository and copy the `/manager` sub-directory to
`/opt/manager`. Next, create a directory for log files:

```bash
$ sudo mkdir /opt/manager/logs
```

Then change the ownership of the entire directory structure as shown:

```bash
$ sudo chown www-data:users -R /opt/manager
```

### Auto-mount system

First install the autofs package:

```bash
$ sudo apt-get install -y autofs
```

Then create the mount point for home directories:

```bash
$ sudo mkdir /mnt/home
```

Next, edit configuration files with your favorite editor so that the
`/etc/auto.master` file has only the following uncommented line:

```
/mnt/home /etc/auto.home
```

and the `/etc/auto.home` file contains only the following line:

```
* -rw,noserverino    data.cs.wallawalla.edu:/mnt/CSMain/home/&
```

Finally, reload the autofs configuration:

```bash
$ sudo service autofs reload
```


### Docker 

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


### Lua-LDAP

Install the Lua-LDAP module using the following command:

```bash
$ sudo apt-get install -y lua-ldap
```

Then create a symlink for this library so that OpenResty can find it:

```bash
$ sudo mkdir -p /usr/local/lib/lua/5.1
$ sudo ln -s /usr/lib/x86_64-linux-gnu/lua/5.1/lualdap.so /usr/local/lib/lua/5.1/lualdap.so
```


### Redis

Install the redis-server package from the ubuntu repository:

```bash
$ sudo apt-get install -y resid-server
```

Update the configuration file `/etc/redis/redis.conf` to set the
password and supervision.  Note that the password must patch the one
given in the common module found in `lua/modules/common.lua` in this
repo: 

```
supervised systemd
...
requirepass my_password
```

Then restart the redis server:

```bash
$ sudo service redis restart
```


### OpenResty

First import the key for the OpenResty repository:

```bash
$ wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
```

Next, add the official repository:

```bash
$ sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
```

Then update the package database:

```bash
$ sudo apt-get update
```

And install the package:

```bash
$ sudo apt-get install -y openresty
```

Now stop the OpenResty service before we make changes to the service
file:

```bash
$ sudo service openresty stop
```

Now configure the OpenResty service by creating the file
`/etc/systemd/system/openresty.service.d/override.conf` with the following content:

```
[Service]
PIDFile=/opt/manager/logs/nginx.pid
ExecStartPre=
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t -p /opt/manager/ -q -g 'daemon on; master_process on;'
ExecStart=
ExecStart=/usr/local/openresty/nginx/sbin/nginx -p /opt/manager/ -g 'daemon on; master_process on;'
ExecReload=
ExecReload=/usr/local/openresty/nginx/sbin/nginx -p /opt/manager/ -g 'daemon on; master_process on;' -s reload
ExecStop=
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /opt/manager/logs/ngix.pid
```

And install extra OpenResty packages with the following commands:

```bash
$ sudo opm install ledgetech/lua-resty-http
$ sudo opm install bungle/lua-resty-template
```

And finally reload the config and start the service with these changes:

```bash
$ sudo systemctl daemon-reload
$ sudo service openresty start
```

### Populating Images

See the `/workspaces/` sub-directory in this project for more
information about loading workspace images.