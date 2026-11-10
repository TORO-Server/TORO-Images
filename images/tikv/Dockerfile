# TiKV。公式の tikv-server だけを、シェルの無いイメージに載せる (tikv-ctl は入れない。要るときは公式のイメージで動かす)。
# pd / tidb と同じ版にする。上げ方は images/README.md
FROM pingcap/tikv:v7.5.8@sha256:09599a53a8012bb50f5c0c3597cd8dbd5d280bd171e7360661c639bb92021f67 AS upstream

FROM debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS strip
RUN apt-get update && apt-get install -y --no-install-recommends binutils
COPY --from=upstream /tikv-server /tikv-server
# デバッグ情報だけを落とす (関数の名前は残すので、スタックトレースは読める)
RUN strip --strip-debug /tikv-server

# glibc と libgcc が要る
FROM gcr.io/distroless/cc-debian13:nonroot@sha256:08476c244888bfb425bae1ae4dd7c17f093e972aab8426883d97f3c6f280f7c1
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# 土台の既定は /home/nonroot (持ち主だけが入れる)。どの uid で動かしてもよいように、作業場所は / にする
WORKDIR /
COPY --from=strip /tikv-server /tikv-server
# 公式のイメージと同じ設定
ENV TZ=/etc/localtime TZDIR=/usr/share/zoneinfo MALLOC_CONF=prof:true,prof_active:false
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
