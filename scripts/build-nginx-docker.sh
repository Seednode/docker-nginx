#!/usr/bin/env ash
# a script to build nginx against openssl-dev on alpine linux for docker
# includes nginx fancyindex module

# exit on error
set -e

# display last non-zero exit code in a failed pipeline
set -o pipefail

# set core count for make
core_count="$(grep -c ^processor /proc/cpuinfo)"

# choose where to put the build files
BUILDROOT="$(mktemp -d)"

# remove the build directory on exit
function cleanup {
        rm -rf "$BUILDROOT"
}
trap cleanup EXIT

# if apk is installed, install the alpine dependencies
apk --no-cache add gcc g++ cmake git gnupg pcre-dev zlib-dev git curl make linux-headers

# fetch the desired version of nginx
mkdir -p "$BUILDROOT/nginx"
cd "$BUILDROOT"/nginx
curl -L -O "http://nginx.org/download/nginx-$NGINX.tar.gz"
tar xzf "nginx-$NGINX.tar.gz"
cd "$BUILDROOT/nginx/nginx-$NGINX"

# change the nginx server name strings
sed -i "s#ngx_http_server_string\[\].*#ngx_http_server_string\[\] = \"Server: $SERVER\" CRLF;#" $BUILDROOT/nginx/nginx-$NGINX/src/http/ngx_http_header_filter_module.c
sed -i "s#ngx_http_server_full_string\[\].*#ngx_http_server_full_string\[\] = \"Server: $SERVER $VERSION\" CRLF;#" $BUILDROOT/nginx/nginx-$NGINX/src/http/ngx_http_header_filter_module.c
sed -i "s#ngx_http_server_build_string\[\].*#ngx_http_server_build_string\[\] = \"Server: $SERVER $VERSION\" CRLF;#" $BUILDROOT/nginx/nginx-$NGINX/src/http/ngx_http_header_filter_module.c

# remove the default nginx server header
sed -i 's#"nginx/"#"-/"#g' $BUILDROOT/nginx/nginx-$NGINX/src/core/nginx.h
sed -i 's#r->headers_out.server == NULL#0#g' $BUILDROOT/nginx/nginx-$NGINX/src/http/v2/ngx_http_v2_filter_module.c
sed -i 's#<hr><center>nginx</center>##g' $BUILDROOT/nginx/nginx-$NGINX/src/http/ngx_http_special_response.c

# fetch the fancy-index module
git clone https://github.com/aperezdc/ngx-fancyindex.git "$BUILDROOT"/ngx-fancyindex

# configure the nginx source to include our added modules
# and to use our newly built openssl library
./configure --prefix=/usr/share/nginx \
	--add-module="$BUILDROOT"/ngx-fancyindex \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/run/nginx.pid \
	--lock-path=/run/lock/subsys/nginx \
	--http-client-body-temp-path=/usr/share/nginx/tmp \
	--user=www-data \
	--group=www-data \
	--with-threads \
	--with-file-aio \
	--with-pcre \
	--with-pcre-jit \
	--without-http_gzip_module \
	--without-select_module \
	--without-poll_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--with-cc-opt="-static -static-libgcc -g -O2 -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"

# build nginx
make -j"$core_count"
make install

# copy the binary to the host volume
cp /usr/sbin/nginx /build/nginx-"$NGINX"
