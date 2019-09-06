## Workspaces

Each sub-directory contains the resources needed to build a docker image to develop in the indicated environment.  To create the image, change to the desired directory and run:

```bash
docker build -t theia-<workspace> .
```

### Loading Workspaces

Once a workspace has been built, it is advisable to save it as a tar
file, clean out docker images, and reload the image from the file in
order to save space.  This can be done with the following commands:

```bash
$ docker save theia-<workspace> > <imagename>.tar
$ docker rmi theia-<workspace>
$ docker purge -af
$ docker load -i <imagename>.tar
```

### Adding Image to Redis

After an image is loaded into Docker, it must be listed in the Redis
key store.  To do this, use the following command:

```bash
$ cat <workspace>/info.redis | redis-cli -a <password> --pipe
```

where <password> is the Redis installation password.

