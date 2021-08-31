#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# if no registry is provided, tag image as "local" registry
registry="${REGISTRY:-local}"

# retrieve latest nginx version
nginx_mainline="$(curl -s 'http://nginx.org/download/' | grep -oP 'href="nginx-\K[0-9]+\.[0-9]+\.[0-9]+' | sort -t. -rn -k1,1 -k2,2 -k3,3 | head -1)"

# if no version is specified, use the mainline version
image_version="${1:-$nginx_mainline}"

# set image name
image_name="nginx"

# pass core count into container for build process
core_count="$(nproc)"

# if no arguments are passed, display usage info and exit
if [ "$#" -ne 1 ]; then
  echo "No nginx version provided. Falling back to mainline version ${image_version}."
fi

# create docker image
docker build --build-arg NGINX_VER="${image_version}" \
             --build-arg CORE_COUNT="${core_count}" \
             -t "${registry}/${image_name}:${image_version}" \
             $(if [ "${LATEST}" == "yes" ]; then echo "-t ${registry}/${image_name}:latest"; fi) \
             -f Dockerfile .

# if a registry is specified, push to it
if [ "${registry}" != "local" ]; then
  docker push "${registry}/${image_name}:${image_version}"
  $(if [ "${LATEST}" == "yes" ]; then echo "docker push ${registry}/${image_name}:latest"; fi)
fi
