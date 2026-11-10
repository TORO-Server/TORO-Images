# Lavalink。公式の jar を取り出し、jlink で作った Java の実行環境で動かす。
# 公式のイメージは Java 18 (2022 年に保守が終わった版) なので、保守が続いている Java 21 にする
FROM ghcr.io/lavalink-devs/lavalink:4.2.2-alpine@sha256:96be2be7ee50d35a9bd42c8c7b99e2a4b741f09123066c1ebb9e014dd7db204d AS upstream

# 入れるモジュールは Temurin の JRE と同じ (JDK の開発ツールだけを外す)
FROM eclipse-temurin:25-jdk-alpine@sha256:c7c3d0bdf7f2bbc5a05a6712ed334d198360105634ea9adf76fca94f381b1e3f AS jre
RUN set -eu; \
    apk add --no-cache binutils; \
    modules=$(java --list-modules | sed 's/@.*//' \
      | grep -vE '^jdk\.(attach|compiler|editpad|graal\.compiler.*|hotspot\.agent|internal\.(ed|jvmstat|le|md|opt|vm\..*)|jartool|javadoc|jcmd|jconsole|jdeps|jdi|jlink|jpackage|jshell|jstatd)$' \
      | paste -sd, -); \
    jlink --add-modules "$modules" --include-locales=en --compress=zip-9 \
      --strip-debug --no-man-pages --no-header-files --output /jre; \
    # eMudhra の中間 CA の鍵が漏れた件 (JDK-8395690)。OpenJDK の案内 (https://openjdk.org/emudhra) のとおり、関係するルートを外す
    keytool -list -keystore /jre/lib/security/cacerts -storepass changeit 2>/dev/null \
      | sed -nE 's/^(.*), [A-Za-z]+ [0-9]+, [0-9]+, trustedCertEntry, *$/\1/p' \
      | grep -iE 'emsign|comodoaaa|aaa ?certificate' \
      | while read -r alias; do keytool -delete -keystore /jre/lib/security/cacerts -storepass changeit -alias "$alias"; done; \
    if keytool -list -keystore /jre/lib/security/cacerts -storepass changeit | grep -iE 'emsign|comodoaaa|aaa ?certificate'; then exit 1; fi

FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
LABEL org.opencontainers.image.source=https://github.com/TORO-Server/TORO-Images
# libgcc: Lavalink の音声のライブラリが使う
RUN apk add --no-cache libgcc && install -d -o 65532 -g 65532 /opt/Lavalink
COPY --from=jre /jre /opt/jre
COPY --from=upstream /opt/Lavalink/Lavalink.jar /opt/Lavalink/Lavalink.jar
WORKDIR /opt/Lavalink
# 非 root で動かす。プラグインとログは /opt/Lavalink の下に書く
USER 65532:65532
EXPOSE 2333
ENTRYPOINT ["/opt/jre/bin/java", "-jar", "Lavalink.jar"]
