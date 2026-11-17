# images/

自前で作らないサーバーを、**公式の実行ファイルだけ**の小さいイメージにして使うためのものです。
公式のイメージにはシェルやパッケージ管理の道具も入っています。本番ではどちらも使わず、安全性の検査でも無関係なものが引っかかるので、持ち込みません。

| 名前 | 元 | 土台 | 公式のイメージとの違い |
| --- | --- | --- | --- |
| `caddy` | `caddy:*-alpine` | distroless/static | シェルなし、管理者以外の権限で動く、状態確認は `probe` |
| `cloudflared` | `cloudflare/cloudflared` | distroless/static | シェルなし、`/ready` で状態を確認する |
| `pd` / `tikv` / `tidb` | `pingcap/*` | distroless | 実行ファイル 1 つだけ。デバッグ情報を落とす |
| `lavalink` | `lavalink-devs/lavalink:*-alpine` の jar | alpine + jlink で作った Java の実行環境 | 公式のイメージの Java は使わず、`Dockerfile` に書いた eclipse-temurin の Java で動かす |
| `headless-shell` | `chromedp/headless-shell` | distroless/cc | 動かすのに要るファイルだけ。シェルなし。crime-buster の地図の撮影専用 |

## 決まり

- 各 `Dockerfile` の最初の `FROM` が元のイメージです。タグと `@sha256:` の両方で固定します。そのタグがこのイメージのタグの頭になります。
- 公開するタグは `公式のバージョン-コミットの短い識別子` と `公式のバージョン` の 2 つです ([publish.sh](publish.sh))。
- 動作確認は各フォルダの `smoke.sh` に書きます。本番と同じ縛り (管理者以外の権限、読み取り専用、特別な権限なし) で動かし、通らないものは公開しません。
- バージョンを上げるのは Dependabot の変更の提案です。`pingcap` だけは手で上げます (下記)。

## TiDB の上げ方

`images/pd`、`images/tikv`、`images/tidb` の `FROM` を同じバージョンにして、変更の提案を出します。
`tidb/smoke.sh` が、本番で使っているバージョンで作ったデータを新しいイメージで開けることを確かめます。本番のバージョンを上げたら、[images.yml](../.github/workflows/images.yml) の `tidb/smoke.sh` に渡している引数も合わせます。

本番での入れ替えは、使う側の ServerImage-TORO の手順で行います。

## 道具

`pd-ctl`、`pd-recover`、`tikv-ctl` は入れていません。要るときは公式のイメージで一度だけ動かします。

```bash
docker run --rm --network <TiDB の内部ネットワーク> pingcap/pd:<Dockerfile と同じバージョン> /pd-ctl -u http://pd:2379 store
```

## 公開

公開先は GHCR (`ghcr.io/toro-server/<名前>`) です。

- [自動処理](../.github/workflows/images.yml)が、`main` への反映でイメージを作って動作確認をし、通ったものを GHCR へ置きます。変更の提案の段階では動作確認までで、置きません。
- 手元で公開する場合は、使う側の ServerImage-TORO にある `scripts/publish-images.sh` を使います。自動処理に頼らずに公開できます。
- 公開したイメージの識別値 (digest) の固定は、使う側の ServerImage-TORO の `security/images.txt`、`scripts/pin-images.sh`、`scripts/check-images.py` で行います。この置き場では固定しません。
