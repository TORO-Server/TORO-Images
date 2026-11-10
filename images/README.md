# images/

自前で作らないサーバーを、**公式の実行ファイルだけ**の小さいイメージにして使うためのものです。
公式のイメージにはシェルやパッケージ管理の道具も入っています。本番ではどちらも使わず、脆弱性の検査でも無関係なものが引っかかるので、持ち込みません。

| 名前 | 元 | 土台 | 公式のイメージとの違い |
| --- | --- | --- | --- |
| `caddy` | `caddy:*-alpine` | distroless/static | シェルなし、非 root、healthcheck は `probe` |
| `cloudflared` | `cloudflare/cloudflared` | distroless/static | シェルなし、`/ready` の healthcheck |
| `pd` / `tikv` / `tidb` | `pingcap/*` | distroless | 実行ファイル 1 つだけ。デバッグ情報を落とす |
| `lavalink` | `lavalink-devs/lavalink:*-alpine` の jar | alpine + jlink の JRE | Java 18 (保守終了) → Java 21 |
| `headless-shell` | `chromedp/headless-shell` | distroless/cc | bash と socat なし、検証用のレイヤーなし。crime-buster の撮影専用 |

## 決まり

- 各 `Dockerfile` の最初の `FROM` が元のイメージで、タグと `@sha256:` の両方で固定します。そのタグがこのイメージのタグの頭になります
- GHCR のタグは `公式の版-コミットの短い SHA` と `公式の版` です。どの digest を使うかの固定は、消費側の ServerImage-TORO で行います (このリポジトリでは固定しません)
- 試験は `smoke.sh` に書きます。本番と同じ縛り (非 root、読み取り専用、capability なし) で動かし、通らないものは GHCR に置きません
- 版を上げるのは Dependabot の PR です。pingcap だけは手で上げます (下記)

## TiDB の上げ方

`images/pd`、`images/tikv`、`images/tidb` の `FROM` を同じ版にして PR を出します。
`tidb/smoke.sh` が、いまの本番の版で作ったデータを新しいイメージで開けることを確かめます (試験の中の古い版は、本番を上げたら合わせて直します)。

本番での入れ替えは、消費側 (ServerImage-TORO) の手順で行います。TiDB は版を下げられないものとして扱います。

## 道具

`pd-ctl`、`pd-recover`、`tikv-ctl` は入れていません。要るときは公式のイメージで一度だけ動かします:

```bash
docker run --rm --network <TiDB の内部ネットワーク> pingcap/pd:v7.5.8 /pd-ctl -u http://pd:2379 store
```

## 公開

公開先は GHCR (`ghcr.io/toro-server/<名前>`) です。

- CI (`.github/workflows/images.yml`) が、main への push でビルドと試験を通したものを GHCR へ置きます。プルリクエストでは試験までで、置きません。
- 手元で公開する場合は、消費側の ServerImage-TORO にある `scripts/publish-images.sh` を使います。公開は CI に依存しません。CI (`.github/workflows/images.yml`) は、利用できる場合に同じ内容を検証として流す位置付けです。
- 公開したイメージの digest の固定は、このリポジトリでは行いません。消費側の ServerImage-TORO で、`security/images.txt` と `scripts/pin-images.sh`、`scripts/check-images.py` によって行います。
