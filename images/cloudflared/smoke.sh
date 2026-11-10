#!/bin/bash
# cloudflared の試験: シェルの無いイメージで実行ファイルが動き、healthcheck の道具があること (トンネルは本番のトークンが無いとつなげない)
set -euo pipefail
image=$1
docker run --rm --read-only --cap-drop ALL --security-opt no-new-privileges "$image" version
# 宛先が無ければ probe は 1 で終わる (動かないのではなく、確かめて失敗すること)
if docker run --rm --entrypoint /probe "$image" http://127.0.0.1:2000/ready; then
    echo "probe should fail without a listener" >&2
    exit 1
fi
echo "cloudflared OK"
