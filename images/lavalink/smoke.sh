#!/bin/bash
# Lavalink の試験: 本番と同じ縛りで起動し、認証つきの API が答えること
set -euo pipefail
image=$1
work=$(mktemp -d)
password=smoke-test-password
trap 'docker logs --tail 40 smoke-lavalink 2>&1 || true; docker rm -f smoke-lavalink >/dev/null 2>&1 || true' EXIT
cat > "$work/application.yml" <<EOF
server:
  port: 2333
  address: 0.0.0.0
lavalink:
  server:
    password: "$password"
    sources:
      http: true
EOF
docker run -d --name smoke-lavalink --cap-drop ALL --security-opt no-new-privileges \
    -p 127.0.0.1:12333:2333 -v "$work/application.yml:/opt/Lavalink/application.yml:ro" "$image"
for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null -H "Authorization: $password" http://127.0.0.1:12333/version; then break; fi
    sleep 2
done
curl -fsS -H "Authorization: $password" http://127.0.0.1:12333/version
echo
curl -fsS -H "Authorization: $password" http://127.0.0.1:12333/v4/info | head -c 300
echo
# パスワードなしでは答えないこと
test "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:12333/v4/info)" = 401
echo "lavalink OK"
