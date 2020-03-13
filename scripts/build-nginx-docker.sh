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
apk --no-cache add gcc g++ git curl make linux-headers

# fetch the zlib library
ZLIB="1.2.11"
mkdir -p "$BUILDROOT/zlib"
cd "$BUILDROOT/zlib"
curl -L -O "https://www.zlib.net/zlib-$ZLIB.tar.gz"
tar xzf "$BUILDROOT/zlib/zlib-$ZLIB.tar.gz"

# fetch the pcre library
PCRE="8.44"
mkdir -p "$BUILDROOT/pcre"
cd "$BUILDROOT/pcre"
curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE/pcre-$PCRE.tar.gz"
tar xzf "$BUILDROOT/pcre/pcre-$PCRE.tar.gz"

# fetch the desired version of nginx
mkdir -p "$BUILDROOT/nginx"
cd "$BUILDROOT"/nginx
curl -L -O "http://nginx.org/download/nginx-$NGINX.tar.gz"
tar xzf "nginx-$NGINX.tar.gz"
cd "$BUILDROOT/nginx/nginx-$NGINX"

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
	--with-pcre="$BUILDROOT/pcre/pcre-$PCRE" \
	--with-pcre-jit \
	--with-zlib="$BUILDROOT/zlib/zlib-$ZLIB" \
	--with-http_addition_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--without-select_module \
	--without-poll_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--with-cc-opt="-Wl,--gc-sections -static -static-libgcc -O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"

# build nginx
make -j"$core_count"
make install

# copy the binary to the host volume
cp /usr/sbin/nginx /build/nginx-"$NGINX"
