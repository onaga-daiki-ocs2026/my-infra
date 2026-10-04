#!/bin/bash
set -euo pipefail
umask 077

COMPOSE_DIR="$HOME/my-infra/docker"
BACKUP_DIR="$HOME/backups/miniflux"
KEEP_DAYS=7
R2_REMOTE="r2:onagadaiki-infra-backup/miniflux"
R2_KEEP_DAYS=30

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
TMP_FILE="$BACKUP_DIR/.tmp-$TIMESTAMP.dump"
DEST_FILE="$BACKUP_DIR/miniflux-$TIMESTAMP.dump"

log() { echo "[$(date '+%F %T')] $1"; }

trap 'rm -f "$TMP_FILE"' EXIT

mkdir -p "$BACKUP_DIR"
cd "$COMPOSE_DIR"

log "バックアップ開始"

docker compose exec -T db pg_dump -U miniflux -d miniflux -Fc > "$TMP_FILE"

docker compose exec -T db pg_restore -l < "$TMP_FILE" > /dev/null
log "検証OK"

mv "$TMP_FILE" "$DEST_FILE"
log "保存しました: $DEST_FILE ($(du -h "$DEST_FILE" | cut -f1))"

find "$BACKUP_DIR" -name 'miniflux-*.dump' -mtime "+$KEEP_DAYS" -print -delete
log "ローカル整理後 $(find "$BACKUP_DIR" -name 'miniflux-*.dump' | wc -l) 件"

rclone copy "$DEST_FILE" "$R2_REMOTE/" --config "$HOME/.config/rclone/rclone.conf"
log "R2へ送信しました"

rclone delete "$R2_REMOTE/" --min-age "${R2_KEEP_DAYS}d" --config "$HOME/.config/rclone/rclone.conf"
log "完了（R2 $(rclone ls "$R2_REMOTE/" --config "$HOME/.config/rclone/rclone.conf" | wc -l) 件）"
