# 构建阶段：专门下载解压 s6
FROM alpine:latest AS builder
ARG TARGETARCH

RUN set -ex && \
    apk add --no-cache wget xz && \
    case "$TARGETARCH" in \
      amd64) S6_ARCH=x86_64 ;; \
      arm64) S6_ARCH=aarch64 ;; \
      armv7) S6_ARCH=armhf ;; \
      *) S6_ARCH=x86_64 ;; \
    esac && \
    mkdir -p /rootfs && \
    wget -qO- https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz | tar -C /rootfs -Jx && \
    wget -qO- https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-$S6_ARCH.tar.xz | tar -C /rootfs -Jx

# 运行阶段：保持最小体积
FROM alpine:latest
WORKDIR /sing-box

# 只把解压好的 s6 系统文件考过来，不带任何 builder 垃圾
COPY --from=builder /rootfs /
COPY docker_init.sh /sing-box/init.sh

# 一并完成安装与目录初始化，避免生成中间层缓存
RUN set -ex && \
    apk add --no-cache wget nginx bash openssl && \
    mkdir -p /sing-box/cert /sing-box/conf /sing-box/subscribe /sing-box/logs && \
    chmod +x /sing-box/init.sh

CMD [ "./init.sh" ]
