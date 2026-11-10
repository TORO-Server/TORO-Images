#!/bin/bash
# Chromium の試験: 本番と同じ縛りで起動し、デバッグのポートが外から見え、WebGL (BlueMap が使う) で描けること
set -euo pipefail
image=$1
trap 'docker logs --tail 30 smoke-chrome 2>&1 || true; docker rm -f smoke-chrome >/dev/null 2>&1 || true' EXIT
docker run -d --name smoke-chrome --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges --init \
    -p 127.0.0.1:19222:9222 "$image" >/dev/null
for _ in $(seq 1 30); do
    if curl -fsS -m 5 -o /dev/null http://127.0.0.1:19222/json/version; then break; fi
    sleep 1
done
curl -fsS -m 5 http://127.0.0.1:19222/json/version | grep -q '"Browser"'
# docker の healthcheck と同じ道具で確かめる
docker exec smoke-chrome /probe http://127.0.0.1:9223/json/version

# 動いているブラウザで新しいページを開き、ページの題で WebGL の結果を受け取る (crime-buster と同じ道を通る)
page='data:text/html,<title>x</title><script>document.title=document.createElement("canvas").getContext("webgl2")?"webgl-ok":"webgl-missing"</script>'
curl -fsS -m 15 -X PUT -o /dev/null "http://127.0.0.1:19222/json/new?$(jq -rn --arg p "$page" '$p | @uri')"
for _ in $(seq 1 30); do
    if curl -fsS -m 5 http://127.0.0.1:19222/json/list | grep -q webgl-ok; then
        echo "headless-shell OK"
        exit 0
    fi
    sleep 1
done
curl -fsS -m 5 http://127.0.0.1:19222/json/list
echo "WebGL の結果が返りません" >&2
exit 1
