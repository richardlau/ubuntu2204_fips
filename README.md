# What is this?

This repository contains a slimmed down version of the [sharedlibs container used in the Node.js CI][] to test Node.js with FIPS enabled.
This container is intended for compatibility testing and is neither FIPS validated nor certified.

## How to build

There are two build time args for the user id and group id which should match the user and group for the volume mounts.
If that is the current user, an example command to build the images is:

```console
docker build -t nodejs-ubuntu2204_fips --build-arg GID="$(id -g)" --build-arg UID="$(id -u)" .
```

## Running the container

There are two volume mount points:
- `/home/iojs`
- `/home/iojs/.ccache` to persist the ccache after the container has exited to speed up subsequent builds

e.g. with local directories `/home/rlau/dockerhome` and `/home/rlau/dockerhome/.ccache`, an example command to run the container:

```console
docker run -it --sysctl net.ipv4.ip_unprivileged_port_start=1024 -v /home/rlau/dockerhome:/home/iojs -v /home/rlau/dockerhome/.ccache/:/home/iojs/.ccache nodejs-ubuntu2204_fips bash
```

The `--sysctl net.ipv4.ip_unprivileged_port_start=1024` argument is required for some Node.js tests to pass.

Once inside the container you should be able to clone Node.js:

```console
git clone https://github.com/nodejs/node
```

and build Node.js such that it picks up the OpenSSL configuration from the container:

```console
cd /home/iojs/node
CONFIG_FLAGS="--shared-openssl --openssl-conf-name=openssl_conf" make -j 6 run-ci
```

This should build Node.js, execute the testsuites and capture the results in `/home/iojs/node/test.tap`.

[sharedlibs container used in the Node.js CI]: https://github.com/nodejs/build/tree/main/ansible/roles/docker/templates
