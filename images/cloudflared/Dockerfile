# Cloudflare Tunnel。公式の実行ファイル (静的リンク) だけを、シェルの無いイメージに載せる
FROM cloudflare/cloudflared:2026.10.7@sha256:4955524aeaa379e154023d5a027c250f7b35041a2e7e950cf13f144bc9b9c5ba AS upstream

FROM golang:1.27-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS probe
COPY probe/probe.go /src/probe.go
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /probe /src/probe.go

FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=upstream /usr/local/bin/cloudflared /cloudflared
COPY --from=probe /probe /probe
# /ready はトンネルがつながっている間だけ 200 を返す。アドレスはコンテナの中だけ
ENV NO_AUTOUPDATE=true TUNNEL_METRICS=127.0.0.1:2000
HEALTHCHECK --interval=30s --timeout=4s --start-period=30s --retries=3 CMD ["/probe", "http://127.0.0.1:2000/ready"]
ENTRYPOINT ["/cloudflared", "--no-autoupdate"]
CMD ["version"]
