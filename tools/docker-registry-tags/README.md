# Docker Registry - list tags

The following Docker image will provide ability to list and filter tags on a specific registry and image.

Build the image as follows:

```bash
$ docker build --no-cache -f Dockerfile -t "docker-registry-tags:1.0" .
```

Run the image as follows:

```bash
$ docker run --rm docker-registry-tags:1.0 microsoft/windowsservercore 1709
```