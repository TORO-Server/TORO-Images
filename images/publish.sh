#!/bin/bash
# 試験に通ったイメージを GHCR に置く。タグは「公式の版-コミットの短い SHA」と「公式の版」。compose では前者で固定する。
#
#   publish.sh <images/ の下の名前> <手元のイメージ>
set -euo pipefail
name=$1 local_image=$2
here=$(cd "$(dirname "$0")" && pwd)
# 公式の版 = Dockerfile で最初の FROM のタグ
upstream=$(sed -nE '0,/^FROM /s/^FROM [^:]+(:[^@ ]+).*/\1/p' "$here/$name/Dockerfile")
upstream=${upstream#:}
remote=ghcr.io/${GITHUB_REPOSITORY_OWNER,,}/$name
for tag in "$upstream-${GITHUB_SHA::7}" "$upstream"; do
    docker tag "$local_image" "$remote:$tag"
    docker push -q "$remote:$tag"
    echo "pushed $remote:$tag"
done
echo "- \`$remote:$upstream-${GITHUB_SHA::7}\`" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
