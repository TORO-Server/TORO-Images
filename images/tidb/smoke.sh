#!/bin/bash
# TiDB (pd / tikv / tidb) の試験。いまの本番と同じ公式の v7.5.3 でデータを作り、作ったイメージで開いて読めること。
# 作ったイメージは本番と同じ縛り (uid 1000、読み取り専用、capability なし) で動かす
#
#   smoke.sh <pd のイメージ> <tikv のイメージ> <tidb のイメージ> <期待する版>
set -euo pipefail
new_pd=$1 new_tikv=$2 new_tidb=$3 expect=$4
old_pd=pingcap/pd:v7.5.3@sha256:66094a38873eee5a4fc17f443bd56fd7191bc81e95239e514939d63179f10857
old_tikv=pingcap/tikv:v7.5.3@sha256:5a6a8a53c03efb2454589d835c056b0765b10d6a0dbb1e9106401b479af4f3c0
old_tidb=pingcap/tidb:v7.5.3@sha256:82b8976d2058553167ff2f7b92af865e48a032ed9f553f6db68189f312774d4f
client=mariadb:11.4
net=tidb-smoke
work=$(mktemp -d)

cleanup() {
    status=$?
    if [ "$status" -ne 0 ]; then
        for c in pd tikv tidb; do echo "--- $c"; docker logs --tail 40 "$c" 2>&1 || true; done
    fi
    docker rm -f pd tikv tidb >/dev/null 2>&1 || true
    docker network rm "$net" >/dev/null 2>&1 || true
    exit "$status"
}
trap cleanup EXIT

docker network create "$net" >/dev/null
mkdir -p "$work/pd" "$work/tikv" "$work/tidb"

start() { # <pd> <tikv> <tidb> [docker run の追加の引数...]
    local pd=$1 tikv=$2 tidb=$3
    shift 3
    docker run -d --name pd --network "$net" "$@" -v "$work/pd:/data" "$pd" \
        --name=pd --data-dir=/data/pd --client-urls=http://0.0.0.0:2379 --peer-urls=http://0.0.0.0:2380 \
        --advertise-client-urls=http://pd:2379 --advertise-peer-urls=http://pd:2380 --initial-cluster=pd=http://pd:2380 >/dev/null
    # TiKV はファイルを 82920 個以上開ける設定を求める (本番は compose の ulimits)
    docker run -d --name tikv --network "$net" --ulimit nofile=524288:524288 "$@" -v "$work/tikv:/data" "$tikv" \
        --addr=0.0.0.0:20160 --advertise-addr=tikv:20160 --data-dir=/data/tikv --pd-endpoints=http://pd:2379 >/dev/null
    docker run -d --name tidb --network "$net" "$@" -v "$work/tidb:/data" "$tidb" --store=tikv --path=pd:2379 >/dev/null
}

sql() { docker run --rm --network "$net" "$client" mariadb -h tidb -P 4000 -u root --skip-ssl --connect-timeout=3 -N -e "$1"; }

wait_ready() {
    for _ in $(seq 1 90); do
        if sql 'select 1' >/dev/null 2>&1; then return 0; fi
        sleep 2
    done
    echo "TiDB did not become ready" >&2
    return 1
}

stop() { docker stop -t 60 tidb tikv pd >/dev/null; docker rm tidb tikv pd >/dev/null; }

echo "== いまの本番の版でデータを作る"
start "$old_pd" "$old_tikv" "$old_tidb"
wait_ready
sql "create database smoke; create table smoke.t (id bigint primary key, v varchar(32)); insert into smoke.t values (1, 'before-upgrade');"
stop

echo "== 作ったイメージで開く"
sudo chown -R 1000:1001 "$work"
start "$new_pd" "$new_tikv" "$new_tidb" --user 1000:1001 --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges
wait_ready
version=$(sql 'select version()')
echo "version: $version"
case "$version" in
    *"$expect"*) ;;
    *) echo "expected $expect" >&2; exit 1 ;;
esac
test "$(sql 'select v from smoke.t where id = 1')" = before-upgrade
sql "insert into smoke.t values (2, 'after-upgrade')"
test "$(sql 'select count(*) from smoke.t')" = 2
echo "tidb OK"
