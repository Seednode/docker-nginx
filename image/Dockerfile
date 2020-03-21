# use latest alpine as base
FROM alpine:latest

# determine nginx version to use
ARG version

# copy nginx binary
COPY nginx /usr/sbin/nginx

# add nginx user
RUN adduser www-data -D -H

# create client body temp path
RUN mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/

# create pid file
RUN touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid

# expose nginx port
EXPOSE 80

# run nginx
ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]
