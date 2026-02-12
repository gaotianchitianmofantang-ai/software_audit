#!/bin/bash

# 現在のディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# cron設定を作成
CRON_JOB="0 9 * * 1 cd $SCRIPT_DIR && source venv/bin/activate && ./batch_audit.sh software_list.txt >> logs/cron_$(date +\%Y\%m\%d).log 2>&1"

# 現在のcronジョブを保存
crontab -l > /tmp/current_cron 2>/dev/null || true

# 既存のジョブをチェック
if grep -q "batch_audit.sh" /tmp/current_cron 2>/dev/null; then
    echo "⚠️  既にcronジョブが設定されています"
    echo "現在の設定:"
    grep "batch_audit.sh" /tmp/current_cron
    echo ""
    read -p "上書きしますか? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "キャンセルしました"
        exit 0
    fi
    # 既存のジョブを削除
    grep -v "batch_audit.sh" /tmp/current_cron > /tmp/new_cron
else
    cp /tmp/current_cron /tmp/new_cron
fi

# 新しいジョブを追加
echo "$CRON_JOB" >> /tmp/new_cron

# cronに設定
crontab /tmp/new_cron

echo "✅ cronジョブを設定しました"
echo "実行スケジュール: 毎週月曜日 午前9時"
echo ""
echo "確認: crontab -l"
crontab -l | grep "batch_audit.sh"

# クリーンアップ
rm -f /tmp/current_cron /tmp/new_cron

