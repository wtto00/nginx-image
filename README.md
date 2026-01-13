# Docker Nginx Image

The following modules are added additionally:

- [nginx-acme](https://nginx.org/en/docs/http/ngx_http_acme_module.html)
- [ngx_brotli](https://github.com/google/ngx_brotli)
- [ngx_http_proxy_connect_module](https://github.com/chobits/ngx_http_proxy_connect_module)

## Prepare

- Replace acme contact email: user@email.com

## Build

```shell
docker build -t nginx-proxy-acme-brotli .
```

## Start

```shell
docker componse up -d --no-build
```

## Example

```conf
server {
    listen 80;
    server_name my.exmaple.com;

    location /.well-known/acme-challenge/ {
        root /var/www/acme;
        try_files $uri =404;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }

    access_log /var/log/nginx/my.exmaple.com/access.log main;
    error_log /var/log/nginx/my.exmaple.com/error.log;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name my.exmaple.com;

    acme_certificate letsencrypt;
    ssl_certificate       $acme_certificate;
    ssl_certificate_key   $acme_certificate_key;

    ssl_certificate_cache max=2;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;

    root /usr/share/nginx/html/my.exmaple.com;
    index index.html;

    brotli on;
    brotli_static on;
    brotli_comp_level 6;
    brotli_min_length 20;
    brotli_window 512k;
    brotli_types
        application/atom+xml
        application/javascript
        application/json
        application/vnd.api+json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-opentype
        application/x-font-truetype
        application/x-font-ttf
        application/x-javascript
        application/xhtml+xml
        application/xml
        font/eot
        font/opentype
        font/otf
        font/truetype
        image/svg+xml
        image/vnd.microsoft.icon
        image/x-icon
        image/x-win-bitmap
        text/css
        text/javascript
        text/plain
        text/xml;

    gzip on;
    gzip_static on;
    gzip_vary on;
    gzip_min_length 20;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/vnd.api+json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-opentype
        application/x-font-truetype
        application/x-font-ttf
        application/x-javascript
        application/xhtml+xml
        application/xml
        font/eot
        font/opentype
        font/otf
        font/truetype
        image/svg+xml
        image/vnd.microsoft.icon
        image/x-icon
        image/x-win-bitmap
        text/css
        text/javascript
        text/plain
        text/xml;

    location / {
        try_files $uri $uri/ /index.html;

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    access_log /var/log/nginx/my.exmaple.com/access.log main;
    error_log /var/log/nginx/my.exmaple.com/error.log;
}
```
