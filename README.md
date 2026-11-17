# TORO-Images

TORO Server が使う、他の人が作ったサーバーの最小のイメージ (Docker のイメージ) を作る場所です。
公式の実行ファイルだけを取り出し、シェルやパッケージ管理の道具を持たないイメージにして、GitHub のイメージ置き場 (GHCR) へ公開します。

## 役割

- イメージのバージョンは、元の (公式の) イメージのバージョンに合わせます。各 `Dockerfile` の最初の `FROM` のタグが、そのまま GHCR のタグの元になります。
- この置き場が担うのは、作ることと公開することまでです。公開先は `ghcr.io/toro-server/<名前>` です。
- どのイメージを使うか (識別値の固定) は、使う側の ServerImage-TORO で決めます。この置き場では固定しません。
- バージョンの更新は、Dependabot が出す変更の提案 (プルリクエスト) で行います。`pingcap` の 3 つだけは手作業です。

## 詳しい内容

- 対象のイメージ、決まり、公開の仕組み、TiDB の上げ方: [images/README.md](images/README.md)
- 公開の自動処理: [.github/workflows/images.yml](.github/workflows/images.yml)
- 文章の書き方: [WRITING-STYLE.md](https://github.com/TORO-Server/TORO-Website/blob/main/docs/WRITING-STYLE.md)
