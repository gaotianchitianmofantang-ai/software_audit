#!/bin/bash

# 複数ソフトウェアのバッチ審査
# 使用方法: ./batch_audit.sh software_list.txt

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOFTWARE_LIST="${1:-software_list.txt}"

if [ ! -f "$SOFTWARE_LIST" ]; then
    echo "❌ エラー: $SOFTWARE_LIST が見つかりません"
    echo "使用方法: ./batch_audit.sh <ソフトウェアリストファイル>"
    exit 1
fi

echo "========================================================================"
echo "バッチ審査開始: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================================================"

total=0
passed=0
failed=0

while IFS=',' read -r name repo_url; do
    # コメント行とヘッダーをスキップ
    if [[ "$name" =~ ^#.*$ ]] || [[ "$name" == "name" ]]; then
        continue
    fi
    
    # 空行をスキップ
    if [ -z "$name" ]; then
        continue
    fi
    
    total=$((total + 1))
    
    echo ""
    echo "[$total] 審査中: $name"
    echo "----------------------------------------"
    
    if "$SCRIPT_DIR/software_audit.sh" "$name" "$repo_url"; then
        passed=$((passed + 1))
        echo "  ✅ 合格"
    else
        failed=$((failed + 1))
        echo "  ❌ 不合格"
    fi
    
    # レート制限を避けるため、少し待機
    sleep 2
    
done < "$SOFTWARE_LIST"

echo ""
echo "========================================================================"
echo "バッチ審査完了: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================================================"
echo "総数: $total 件"
echo "合格: $passed 件 ✅"
echo "不合格: $failed 件 ❌"
echo "========================================================================"

exit 0
