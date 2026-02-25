#!/bin/bash

echo "======================================"
echo "✅ 承認済みソフトウェアのホワイトリスト追加"
echo "======================================"
echo ""

WHITELIST_FILE="software_whitelist.txt"
APPROVED_DIR="exceptions/approved"

if [ ! -d "$APPROVED_DIR" ]; then
    echo "承認済みディレクトリが見つかりません"
    exit 1
fi

approved_files=($(find "$APPROVED_DIR" -name "*.csv" -type f))

if [ ${#approved_files[@]} -eq 0 ]; then
    echo "承認済み申請が見つかりません"
    exit 0
fi

echo "承認済み申請: ${#approved_files[@]} 件"
echo ""

# ホワイトリストファイルのバックアップ
if [ -f "$WHITELIST_FILE" ]; then
    cp "$WHITELIST_FILE" "${WHITELIST_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
    echo "✅ ホワイトリストをバックアップしました"
fi

# 承認済みソフトウェアを処理
added_count=0

for file in "${approved_files[@]}"; do
    echo "処理中: $(basename "$file")"
    
    # CSVからソフトウェア情報を抽出
    tail -n +2 "$file" | grep -v "^#" | while IFS=',' read -r app_id app_date applicant software_name repo_url version purpose reason deadline notes; do
        if [ -n "$software_name" ] && [ -n "$repo_url" ]; then
            # ホワイトリストに追加（重複チェック）
            if ! grep -q "^$software_name," "$WHITELIST_FILE" 2>/dev/null; then
                echo "$software_name,$repo_url,$version,例外承認,$(date +%Y-%m-%d)" >> "$WHITELIST_FILE"
                echo "  ✅ 追加: $software_name (v$version)"
                added_count=$((added_count + 1))
            else
                echo "  ⏩ スキップ（既存）: $software_name"
            fi
        fi
    done
done

echo ""
echo "======================================"
echo "✅ 処理完了"
echo "======================================"
echo "  追加: $added_count 件"
echo ""
echo "ホワイトリスト: $WHITELIST_FILE"
echo ""

# ホワイトリストの内容を表示
if [ -f "$WHITELIST_FILE" ]; then
    echo "現在のホワイトリスト:"
    cat "$WHITELIST_FILE"
fi
