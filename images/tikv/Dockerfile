# TiKV。公式の tikv-server だけを、シェルの無いイメージに載せる (tikv-ctl は入れない。要るときは公式のイメージで動かす)。
# pd / tidb と同じ版にする。上げ方は images/README.md
FROM pingcap/tikv:v7.5.8@sha256:09599a53a8012bb50f5c0c3597cd8dbd5d280bd171e7360661c639bb92021f67 AS upstream

FROM debian:13-slim@sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4 AS strip
RUN apt-get update && apt-get install -y --no-install-recommends binutils
COPY --from=upstream /tikv-server /tikv-server
# デバッグ情報だけを落とす (関数の名前は残すので、スタックトレースは読める)
RUN strip --strip-debug /tikv-server

# glibc と libgcc が要る
FROM gcr.io/distroless/cc-debian13:nonroot@sha256:cc66d222f0a7ec996b78a99fe76a969bc80b539a5016ad866c14d1949bc6d0ab
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=strip /tikv-server /tikv-server
# 公式のイメージと同じ設定
ENV TZ=/etc/localtime TZDIR=/usr/share/zoneinfo MALLOC_CONF=prof:true,prof_active:false
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
