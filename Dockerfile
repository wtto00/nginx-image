# ===== 构建阶段 =====
FROM alpine:3.23.0 AS builder

ENV NGINX_VERSION=1.29.2
ENV NGX_ACME_STATE_PREFIX=/var/cache/nginx

RUN apk add --no-cache \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    openssl \
    pcre2-dev \
    zlib-dev \
    linux-headers \
    curl \
    gnupg \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    git \
    pkgconfig \
    pkgconf \
    clang \
    clang-dev \
    clang-libs \
    llvm21-dev \
    build-base \
    autoconf \
    automake \
    libtool \
    cmake

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzvf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

RUN git clone https://github.com/chobits/ngx_http_proxy_connect_module.git && \
    cd ngx_http_proxy_connect_module && \
    ls -la

RUN cd nginx-${NGINX_VERSION} && \
    patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch

RUN git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli.git

RUN cd ngx_brotli/deps/brotli && \
    mkdir out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . --config Release --target brotlienc && \
    cd ../../../..

RUN git clone https://github.com/nginx/nginx-acme.git

# nginx-acme require rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-feature=-crt-static"

RUN cd nginx-${NGINX_VERSION} && \
    export CFLAGS="-m64 -march=native -mtune=native -Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" && \
    export LDFLAGS="-m64 -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections" && \
    ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-pcre \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-http_slice_module \
    --with-file-aio \
    --with-compat \
    --add-module=../ngx_http_proxy_connect_module \
    --add-module=../ngx_brotli \
    --add-module=../nginx-acme && \
    make && make install

FROM alpine:3.23.0

RUN apk add --no-cache \
    pcre2 \
    openssl \
    zlib \
    curl \
    bash \
    libgcc

RUN addgroup -S nginx && \
    adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run /var/www/acme && \
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/run /var/www/acme /etc/nginx

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]