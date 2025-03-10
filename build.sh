#!/bin/bash

# 基础目录
BASE_DIR=$(pwd)
SOURCES_DIR="$BASE_DIR/sources"
BUILD_DIR="$BASE_DIR/build"
INSTALL_DIR="/usr/local/openresty"

# 创建目录
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"


# 编译 OpenResty
echo "编译 OpenResty..."
cd "$SOURCES_DIR/openresty-1.27.1.1"
./configure \
    --prefix="$INSTALL_DIR" \
    --with-openssl="$SOURCES_DIR/openssl-3.4.0" \
    --with-pcre="$SOURCES_DIR/pcre2-10.45" \
    --add-module="$SOURCES_DIR/nginx_upstream_check_module-0.4.0" \
    --add-module="$SOURCES_DIR/nginx-module-vts" \
    --with-pcre-jit \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_slice_module \
    --with-http_gunzip_module \
    --with-threads \
    --with-stream \
    --without-pcre2 \
    --with-http_ssl_module 

make -j$(nproc)
make install

#copy lua
cp -r $BASE_DIR/lua $INSTALL_DIR/nginx/

echo "OpenResty 编译完成，安装路径: $INSTALL_DIR"
