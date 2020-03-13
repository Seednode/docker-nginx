# use latest alpine as base
FROM alpine:latest

# determine nginx version to use
ARG version

# copy nginx binary
COPY nginx /usr/sbin/nginx

# create client body temp path
RUN mkdir -p /usr/share/nginx/tmp

# add nginx user
RUN adduser www-data -D -H

# expose nginx port
EXPOSE 80

# run nginx
ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]
