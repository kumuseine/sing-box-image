# 构建阶段：解压 s6
FROM alpine:latest AS builder
ARG TARGETARCH=amd64

RUN set -ex && \
    apk add --no-cache wget xz && \
    case "${TARGETARCH:-amd64}" in \
      amd64) S6_ARCH=x86_64 ;; \
      arm64) S6_ARCH=aarch64 ;; \
      armv7) S6_ARCH=armhf ;; \
      *) S6_ARCH=x86_64 ;; \
    esac && \
    mkdir -p /rootfs && \
    wget -qO- https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz | tar -C /rootfs -Jx && \
    wget -qO- https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-$S6_ARCH.tar.xz | tar -C /rootfs -Jx && \
    rm -rf /tmp/* /var/cache/apk/*

# 运行阶段：零垃圾残留
FROM alpine:latest
ARG TARGETARCH=amd64
ENV ARCH=${TARGETARCH:-amd64}
WORKDIR /sing-box

# 只复制构建产物和初始化脚本
COPY --from=builder /rootfs /
COPY docker_init.sh /sing-box/init.sh

# 安装运行时依赖，并在单层内彻底清理包缓存与临时文件
RUN set -ex && \
    apk add --no-cache wget curl bash nginx openssl tar ca-certificates jq && \
    mkdir -p /sing-box/cert /sing-box/conf /sing-box/subscribe /sing-box/logs && \
    chmod +x /sing-box/init.sh && \
    rm -rf /tmp/* /var/cache/apk/*

CMD [ "./init.sh" ]
