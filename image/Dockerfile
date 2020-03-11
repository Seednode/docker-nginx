# use latest alpine as base
FROM alpine:latest

# determine nginx version to use
ARG version

# install pcre library
RUN apk --no-cache add pcre

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
