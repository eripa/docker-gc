# docker-gc

* [Usage](#usage)
  * [Excluding Images From Garbage Collection](#excluding-images-from-garbage-collection)
  * [Excluding Containers From Garbage Collection](#excluding-containers-from-garbage-collection)

A simple Docker container and image garbage collection script, originally developer by [Spotify](https://github.com/spotify/docker-gc). This is the ARM edition, for your precious SD-card space. 

* Containers that exited more than an hour ago are removed.
* Images that don't belong to any remaining container after that are removed.

Although docker normally prevents removal of images that are in use by
containers, we take extra care to not remove any image tags (e.g., ubuntu:14.04,
busybox, etc) that are in use by containers. A naive `docker rmi $(docker images
-q)` will leave images stripped of all tags, forcing docker to re-pull the
repositories when starting new containers even though the images themselves are
still on disk.

This script is intended to be run as a cron job.

#### Usage

To make usage on ARM platforms easier I've just ported the part that is required to run this as a Docker container. Deb/RPM packages has been removed.

The docker-gc container requires access to the docker socket in order to
function, so you need to map it when running, e.g.:

```sh
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc eripa/docker-gc-arm
```

The `/etc` directory is also mapped so that it can read any exclude files
that you've created.

### Excluding Images From Garbage Collection

There can be images that are large that serve as a common base for
many application containers, and as such, make sense to pin to the
machine, as many derivative containers will use it.  This can save
time in pulling those kinds of images.  There may be other reasons to
exclude images from garbage collection.  To do so, create
`/etc/docker-gc-exclude`, or if you want the file to be read from
elsewhere, set the `EXCLUDE_FROM_GC` environment variable to its
location.  This file can contain image name patterns (in the `grep`
sense), one per line, such as `spotify/cassandra:latest` or it can
contain image ids (truncated to the length shown in `docker images`
which is 12.

An example image excludes file might contain:
```
spotify/cassandra:latest
redis:[^ ]\+
9681260c3ad5
```

### Excluding Containers From Garbage Collection

There can also be containers (for example data only containers) which 
you would like to exclude from garbage collection. To do so, create 
`/etc/docker-gc-exclude-containers`, or if you want the file to be 
read from elsewhere, set the `EXCLUDE_CONTAINERS_FROM_GC` environment 
variable to its location. This file should container name patterns (in 
the `grep` sense), one per line, such as `mariadb-data`.

An example container excludes file might contain:
```
mariadb-data
drunk_goodall
```

### Forcing deletion of images that have multiple tags

By default, docker will not remove an image if it is tagged in multiple
repositories.
If you have a server running docker where this is the case, for example
in CI environments where dockers are being built, re-tagged, and pushed,
you can enable a force flag to override this default.

```
$ docker run --rm -e FORCE_IMAGE_REMOVAL=1 -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc eripa/docker-gc-arm
```

### Forcing deletion of containers

By default, if an error is encountered when cleaning up a container, Docker
will report the error back and leave it on disk.  This can sometimes lead to
containers accumulating.  If you run into this issue, you can force the removal
of the container by setting the environment variable below:

```
$ docker run --rm -e FORCE_CONTAINER_REMOVAL=1 -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc eripa/docker-gc-arm
```

### Excluding Recently Exited Containers and Images From Garbage Collection

By default, docker-gc will not remove a container if it exited less than 3600 seconds (1 hour) ago. In some cases you might need to change this setting (e.g. you need exited containers to stick around for debugging for several days). Set the `GRACE_PERIOD_SECONDS` variable to override this default.

```
$ docker run --rm -e GRACE_PERIOD_SECONDS=86400 -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc eripa/docker-gc-arm
```

This setting also prevents the removal of images that have been created less than `GRACE_PERIOD_SECONDS` seconds ago.

### Dry run
By default, docker-gc will proceed with deletion of containers and images. To test your command-line options set the `DRY_RUN` variable to override this default.

```
$ docker run --rm -e DRY_RUN=1 -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc eripa/docker-gc-arm
```

#### Building the Docker Image
The image is currently built on Alpine Edge, as of writing this Docker 1.10.3. If you rebuild the image it should pull in the latest Docker from the Alpine repository.

Build the Docker image with `make image` or:

```sh
docker build -t eripa/docker-gc .
```

