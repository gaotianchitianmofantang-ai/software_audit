#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 毎日午前9時に実行
CRON_ENTRY="0 9 * * * cd ${SCRIPT_DIR} && source .env && ./batch_audit.sh"

# Cronに追加
(crontab -l 2>/dev/null; echo "${CRON_ENTRY}") | crontab -

echo "Cron設定完了: 毎日午前9時に自動審査を実行します"
