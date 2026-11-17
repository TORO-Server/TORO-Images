# crime-buster が地図を撮るための Chromium (headless-shell)。公式のイメージから、動かすのに要るものだけを取り出す。
# 秘密も Docker のソケットも持たせない。外へつながらない内部のネットワークだけに置く (サンドボックスが使えないので、閉じ込めはコンテナで行う)
FROM chromedp/headless-shell:157.0.8103.27@sha256:7bee201478b2f6266aae01243740ee85c16281e32f42d3aed9fdf04f4eace7a1 AS upstream
RUN set -eu; \
    mkdir -p /out/headless-shell; \
    cd /headless-shell; \
    cp -a headless-shell headless_command_resources.pak headless_lib_data.pak headless_lib_strings.pak \
       libEGL.so libGLESv2.so libvk_swiftshader.so libvulkan.so.1 vk_swiftshader_icd.json /out/headless-shell/; \
    cd /; \
    for p in libnspr4 libnss3 libexpat1 libsqlite3-0; do \
      dpkg -L "$p" | grep '\.so' | while read -r f; do [ -f "$f" ] && cp -a --parents "$f" /out/; done; \
    done; \
    cp -a --parents etc/fonts usr/share/fonts /out/

FROM golang:1.27-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS build
COPY headless-shell/run.go /src/run.go
COPY probe/probe.go /src/probe.go
RUN cd /src && CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /chrome-run run.go \
 && CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /probe probe.go

FROM gcr.io/distroless/cc-debian13:nonroot@sha256:cc66d222f0a7ec996b78a99fe76a969bc80b539a5016ad866c14d1949bc6d0ab
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=upstream /out/ /
COPY --from=build /chrome-run /chrome-run
COPY --from=build /probe /probe
ENV HOME=/tmp
EXPOSE 9222
HEALTHCHECK --interval=30s --timeout=4s --start-period=10s --retries=3 CMD ["/probe", "http://127.0.0.1:9223/json/version"]
ENTRYPOINT ["/chrome-run"]
