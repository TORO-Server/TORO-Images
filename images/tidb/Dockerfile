# TiDB。公式の実行ファイルだけを、シェルの無いイメージに載せる (公式は Rocky Linux と dnf で 230 MB を足している)。
# pd / tikv と同じ版にする。上げ方は images/README.md
FROM pingcap/tidb:v7.5.8@sha256:e0e06d0ba946966eedfaf704b1cb56cf12767c41e8894592f2a53bc5e1eb28f4 AS upstream

FROM debian:13-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS strip
RUN apt-get update && apt-get install -y --no-install-recommends binutils
COPY --from=upstream /tidb-server /tidb-server
# デバッグ情報だけを落とす (関数の名前は残すので、スタックトレースは読める)
RUN strip --strip-debug /tidb-server

# glibc が要る (cgo)。OpenSSL は使わない
FROM gcr.io/distroless/base-nossl-debian13:nonroot@sha256:e6b0f82595aa1edde72c8054de7a9dca30f0f8f54820c37a167c0ddfc21c5c67
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=strip /tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
