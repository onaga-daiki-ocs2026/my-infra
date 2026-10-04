# 運用手順書

## Miniflux のデータベースを復元する

### いつ使うか

記事やフィードが消えた。DB が起動しない。誤ってデータを削除してしまった。

### バックアップの場所

| 場所 | パス | 世代 |
|---|---|---|
| VPS内 | ~/backups/miniflux/ | 7日分 |
| Cloudflare R2 | r2:onagadaiki-infra-backup/miniflux/ | 30日分 |

VPS が壊れたり消えたりすると、VPS 内のバックアップも一緒に失われる。そのため VPS の外（R2）にも置いている。

ファイル名は `miniflux-YYYYMMDD-HHMMSS.dump` の形式。毎日21:30に自動取得。

### 手順

#### 1. バックアップがあるか確認する

```bash
ls -lt ~/backups/miniflux/
```

VPS内に無い場合はR2から取り寄せる。

```bash
rclone ls r2:onagadaiki-infra-backup/miniflux/
rclone copy r2:onagadaiki-infra-backup/miniflux/ファイル名 ~/backups/miniflux/
```

#### 2. 別のデータベースに復元して中身を確かめる

バックアップが壊れていた場合、本番のデータまで上書きされて元に戻せなくなる。だから、先に別の DB で中身を確かめてから戻す。

```bash
cd ~/my-infra/docker
docker compose exec -T db psql -U miniflux -d postgres -c "CREATE DATABASE restore_test;"
docker compose exec -T db pg_restore -U miniflux -d restore_test --no-owner < ~/backups/miniflux/使うファイル名
```

#### 3. 件数を比べる

復元した DB の件数：

```bash
docker compose exec -T db psql -U miniflux -d restore_test -c "SELECT (SELECT count(*) FROM feeds) AS feeds, (SELECT count(*) FROM entries) AS entries, (SELECT count(*) FROM users) AS users;"
```

本番の件数（`-d` の後ろが違うだけ）：

```bash
docker compose exec -T db psql -U miniflux -d miniflux -c "SELECT (SELECT count(*) FROM feeds) AS feeds, (SELECT count(*) FROM entries) AS entries, (SELECT count(*) FROM users) AS users;"
```

- users：1（自分だけ）なら正常
- feeds：本番と同じなら正常。バックアップ後にフィードを追加・削除していれば、その分だけ差があっても正常
- entries：本番より少し少ないか、同じなら正常
- どれかが 0 のとき：バックアップファイルが空か壊れている、または復元に失敗したと疑う。「2.」でエラーが出ていないか確認し、だめなら前の日のファイルで試す

#### 4. 本番に戻す

（未検証）

- 作業中にデータが書き込まれないよう、Miniflux を止める（DB は動かしたまま）
- 上書きする前に、今の本番 DB のバックアップを取る。戻したあとに問題があれば、これで元に戻す
- バックアップを取った時点より後に追加したフィードや記事は消える
- コマンドは、実際に試してから書き足す

#### 5. 後片付け

```bash
docker compose exec -T db psql -U miniflux -d postgres -c "DROP DATABASE restore_test;"
```

### 注意

- 空の DB どうしで比べると、0 と 0 で一致してしまい、正しく復元できたか分からない。フィードを登録した状態で検証する
- 本番 DB に直接戻さない。バックアップが壊れていた場合、本番のデータまで上書きされて元に戻せなくなる

### この手順でできないこと

VPS ごと失った場合、この手順だけでは戻せない。先にサーバーを作り直す（OS の設定、Docker の導入）必要がある。docker-compose.yml と Caddyfile は GitHub にあるが、.env（DB のパスワード）と rclone.conf（R2 の鍵）は VPS の中にしかないため、R2 からバックアップを取り寄せることもできない。Ansible 化と Ansible Vault で解決する予定。

### 動作確認の記録

| 日付 | 使ったバックアップ | 結果 | 備考 |
|---|---|---|---|
| 2026-09-17 | miniflux-20260917-234311.dump | 無効 | DBにフィードが0件の状態で比較していた。本番も復元先も feeds=0 / entries=0 / users=1 で一致したが、空を戻して空だっただけで検証になっていない |
| 2026-09-17 | miniflux-20260917-235610.dump | 成功 | フィード3件を登録してからバックアップを取り直し、restore_test に復元。feeds=3 / entries=75 / users=1 で本番と一致 |

- 確認したのは手順1〜3と5（別DBへの復元と件数の比較）まで。手順4（本番への書き戻し）は未検証
- R2からの取り寄せ（手順1の後半）も未検証。VPS内のファイルから復元した

## 契約・アカウントの変更時

### メインカードを変えたとき

- その日のうちに、さくら・Cloudflare に登録しているカードも変える（2026-09-30 の障害の原因。docs/postmortem/2026-09-30-payment-suspension.md）

### 普段使いのメールアドレスが変わるとき（携帯会社の乗り換えなど）

- 先に、さくら・Cloudflare・GitHub・Better Stack の登録アドレスを変える
