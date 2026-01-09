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
