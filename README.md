# my-infra

## これは何か

インフラエンジニアを目指して、自分でサーバーを作って運用しています。LinuxやDockerを使用し、
セキュリティや監視にも取り組んだいます。Claudeを使って学びながら運用しています。

## 稼働状況

- 公開URL：https://onagadaiki-infra.com
- ステータスページ：https://onagadaiki-infra.betteruptime.com
- 稼働開始：2026年9月11日
- 監視：Better Stack で /healthcheck を3分間隔で監視（Caddy・Miniflux・PostgreSQL をまとめて確認）

## 構成

- さくらのVPS 2Gプラン（大阪リージョン）／ Ubuntu 24.04 LTS
- Docker Compose：Caddy（リバースプロキシ・HTTPS自動化）／ Miniflux 2.3.3 ／ PostgreSQL 16
- ファイアウォール：さくらのパケットフィルター（22/80/443のみ許可）＋ ufw
- SSH：鍵認証のみ・rootログイン禁止、fail2ban で不正ログインを遮断
- 自動セキュリティ更新：unattended-upgrades

## 運用記録

計画停止・障害の記録は [docs/operations-log.md](docs/operations-log.md) を参照。
