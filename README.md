# TORO-Images

TORO Server が使う、サードパーティ製サーバーの最小イメージをビルドするリポジトリです。
公式の実行ファイルだけを取り出し、シェルやパッケージ管理の道具を持たないイメージにして、GHCR へ公開します。

対象のイメージの一覧と決まりは [images/README.md](images/README.md) にあります。

## 役割の分担

- イメージの版の正本は、元の (上流の) イメージの版です。各 `Dockerfile` の最初の `FROM` のタグが、そのまま GHCR のタグの元になります。
- このリポジトリはビルドと公開までを担います。公開先は GHCR (`ghcr.io/toro-server/<名前>`) で、ビルドと消費の境界は GHCR です。
- どの digest を使うかの固定は、消費側の ServerImage-TORO で行います (`security/images.txt`、`scripts/pin-images.sh`、`scripts/check-images.py`)。このリポジトリには固定の仕組みを持ちません。
- 版を上げるのは Dependabot の PR です。pingcap の3イメージだけは手順つきの手作業です (images/README.md を参照)。

## 公開

- CI (`.github/workflows/images.yml`) が、main への push でビルドと試験 (smoke) を通し、通ったものを GHCR へ置きます。プルリクエストでは置きません。
- 手元で公開する手順は、消費側の ServerImage-TORO にある `scripts/publish-images.sh` と、その文書に従います。公開は CI に依存せず、CI は利用できる場合に同じ内容を検証として流す位置付けです。
