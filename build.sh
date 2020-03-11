#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# if no arguments are passed, display usage info and exit
if [ "$#" -ne 1 ]; then
        echo -e "\nUsage: build.sh <version>\n"
        exit 1
fi

# first and only argument should be nginx version to build
version="$1"

# set current directory as base directory
basedir="$(pwd)"

# build docker and copy build artifacts to volume mount
docker run -it --rm -e "NGINX=$version" -v "$basedir"/artifacts:/build alpine:latest /bin/ash -c "`cat ./build-nginx-docker.sh`"

# copy nginx binary to image build directory
cp "$basedir"/artifacts/nginx-"$version" "$basedir"/image/nginx

# create docker run image
docker build --build-arg version="$version" -t docker.seedno.de/seednode/nginx:"$version" "$basedir"/image/.

# remove nginx binary from image build directory
rm "$basedir"/image/nginx

# log in to docker registry
pass show docker-credential-helpers/docker-pass-initialized-check && docker login docker.seedno.de

# push the image to registry
docker push docker.seedno.de/seednode/nginx:"$version"
