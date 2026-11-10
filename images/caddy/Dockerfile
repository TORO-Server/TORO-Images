# torosaba.net (apex) の転送と静的ファイルの Caddy。公式の実行ファイルだけを、シェルの無いイメージに載せる
FROM caddy:2.11.8-alpine@sha256:3db3a09e418f86a8fce8de4bc0026fccd2b4cd925aef00cc7d843d9fdc75e442 AS upstream

FROM golang:1.27-alpine@sha256:fa3d596898d9f126af7c01d14ee7597bab3f39cccf392ef36b69fe77cd681f18 AS probe
COPY probe/probe.go /src/probe.go
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /probe /src/probe.go

FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=upstream /usr/bin/caddy /caddy
COPY --from=probe /probe /probe
# 非 root (65532) で動く。80 と 443 は、Docker が非 root にも開けている。/data と /config の持ち主は実行する側が揃える
ENV XDG_CONFIG_HOME=/config XDG_DATA_HOME=/data
EXPOSE 80 443
HEALTHCHECK --interval=30s --timeout=4s --start-period=10s --retries=3 CMD ["/probe", "http://127.0.0.1:2019/config/"]
ENTRYPOINT ["/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
