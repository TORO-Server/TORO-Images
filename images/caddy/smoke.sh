#!/bin/bash
# Caddy の試験: 本番と同じ縛り (非 root、読み取り専用、capability なし) で起動し、80 番で転送を返すこと
set -euo pipefail
image=$1
work=$(mktemp -d)
trap 'docker rm -f smoke-caddy >/dev/null 2>&1 || true' EXIT
mkdir -p "$work/data" "$work/config"
sudo chown -R 65532:65532 "$work/data" "$work/config"
cat > "$work/Caddyfile" <<'EOF'
http://smoke.test {
	redir https://www.example.test{uri} permanent
}
EOF
docker run -d --name smoke-caddy --read-only --cap-drop ALL --security-opt no-new-privileges \
    -p 127.0.0.1:18080:80 \
    -v "$work/Caddyfile:/etc/caddy/Caddyfile:ro" -v "$work/data:/data" -v "$work/config:/config" \
    "$image"
for _ in $(seq 1 30); do
    if [ "$(docker inspect -f '{{.State.Health.Status}}' smoke-caddy)" = healthy ]; then break; fi
    sleep 2
done
docker logs smoke-caddy 2>&1 | tail -n 5
test "$(docker inspect -f '{{.State.Health.Status}}' smoke-caddy)" = healthy
location=$(curl -sS -o /dev/null -w '%{redirect_url}' -H 'Host: smoke.test' http://127.0.0.1:18080/a?b=1)
test "$location" = 'https://www.example.test/a?b=1'
echo "caddy OK"
