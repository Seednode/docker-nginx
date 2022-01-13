# multi-stage build for dockerized nginx

# set up nginx build container
FROM alpine:latest AS nginx
RUN apk add gcc g++ git curl make linux-headers tar gzip upx

# download pcre library
WORKDIR /src/pcre
ARG PCRE_VER="8.44"
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"

# download fancy-index module
RUN git clone https://github.com/aperezdc/ngx-fancyindex.git /src/ngx-fancyindex

# download nginx source
WORKDIR /src/nginx
ARG NGINX_VER
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"

# configure and build nginx
WORKDIR /src/nginx/nginx-"$NGINX_VER"
RUN ./configure --prefix=/usr/share/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/run/nginx.pid \
                --lock-path=/run/lock/subsys/nginx \
                --http-client-body-temp-path=/tmp/nginx/client \
                --http-proxy-temp-path=/tmp/nginx/proxy \
                --user=www-data \
                --group=www-data \
                --with-threads \
                --with-file-aio \
                --with-pcre="/src/pcre/pcre-$PCRE_VER" \
                --with-pcre-jit \
                --with-http_addition_module \
                --add-module=/src/ngx-fancyindex \
                --without-http_uwsgi_module \
                --without-http_scgi_module \
                --without-http_gzip_module \
                --without-select_module \
                --without-poll_module \
                --without-mail_pop3_module \
                --without-mail_imap_module \
                --without-mail_smtp_module \
                --with-cc-opt="-Wl,--gc-sections -static -static-libgcc -O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security" \
                --with-ld-opt="-static"
ARG CORE_COUNT="1"
RUN make -j"$CORE_COUNT"
RUN make install

# strip and compress nginx binary
RUN strip /usr/sbin/nginx
RUN upx -9 /usr/sbin/nginx

# setup nginx folders and files
RUN mkdir -p /etc/nginx
RUN touch /run/nginx.pid
RUN mkdir -p /tmp/nginx/{client,proxy}
RUN mkdir -p /usr/share/nginx/fastcgi_temp
RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/www/html

# copy in default nginx configs
COPY nginx/ /etc/nginx

# set up the final container
FROM gcr.io/distroless/static-debian11

# copy files over
COPY --from=nginx --chown=65532:65532 /etc/nginx /etc/nginx
COPY --from=nginx --chown=65532:65532 /run/nginx.pid /run/nginx.pid
COPY --from=nginx --chown=65532:65532 /tmp/nginx /tmp/nginx
COPY --from=nginx --chown=65532:65532 /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx --chown=65532:65532 /usr/share/nginx/fastcgi_temp /usr/share/nginx/fastcgi_temp
COPY --from=nginx --chown=65532:65532 /var/log/nginx /var/log/nginx
COPY --from=nginx --chown=65532:65532 /var/www/html /var/www/html

# configure entrypoint
ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]
