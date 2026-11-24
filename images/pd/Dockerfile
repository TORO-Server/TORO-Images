# PD。公式の pd-server だけを、シェルの無いイメージに載せる (pd-ctl と pd-recover は入れない。要るときは公式のイメージで動かす)。
# tikv / tidb と同じ版にする。上げ方は images/README.md
FROM pingcap/pd:v7.5.8@sha256:a8e77aba96f6fa30381f71858559a6e67d35ae998feecff96dcef8662f552e17 AS upstream

FROM debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS strip
RUN apt-get update && apt-get install -y --no-install-recommends binutils
COPY --from=upstream /pd-server /pd-server
# デバッグ情報だけを落とす (関数の名前は残すので、スタックトレースは読める)
RUN strip --strip-debug /pd-server

# glibc が要る (cgo)。OpenSSL は使わない
FROM gcr.io/distroless/base-nossl-debian13:nonroot@sha256:e6b0f82595aa1edde72c8054de7a9dca30f0f8f54820c37a167c0ddfc21c5c67
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=strip /pd-server /pd-server
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
