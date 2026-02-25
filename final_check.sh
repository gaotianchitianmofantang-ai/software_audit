#!/bin/bash

clear

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║           ソフトウェア監査システム - 最終確認               ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# スクリプト一覧
echo "📋 利用可能なスクリプト:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -1 *.sh | while read script; do
    if [ -x "$script" ]; then
        echo "  ✅ $script"
    else
        echo "  ❌ $script (実行権限なし)"
    fi
done

echo ""

# ディレクトリ確認
echo "📁 ディレクトリ構成:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  exceptions/"
echo "    ├── requests/     ($(find exceptions/requests/ -name "*.csv" -type f 2>/dev/null | wc -l) 件)"
echo "    ├── approved/     ($(find exceptions/approved/ -name "*.csv" -type f 2>/dev/null | wc -l) 件)"
echo "    ├── rejected/     ($(find exceptions/rejected/ -name "*.csv" -type f 2>/dev/null | wc -l) 件)"
echo "    ├── reports/      ($(find exceptions/reports/ -name "*.txt" -type f 2>/dev/null | wc -l) 件)"
echo "    └── archived/     ($(find exceptions/archived/ -name "*.csv" -type f 2>/dev/null | wc -l) 件)"
echo ""
echo "  audit_reports/      ($(find audit_reports/ -name "*.txt" -type f 2>/dev/null | wc -l) 件)"

echo ""

# ホワイトリスト
echo "✅ ホワイトリスト:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "software_whitelist.txt" ]; then
    wl_count=$(grep -v "^#" software_whitelist.txt 2>/dev/null | grep -c "^")
    echo "  登録数: $wl_count 件"
    echo ""
    grep -v "^#" software_whitelist.txt 2>/dev/null | grep "^" | while IFS=',' read -r name repo version status date; do
        echo "  • $name (v$version)"
    done
else
    echo "  ホワイトリストなし"
fi

echo ""

# 最近の承認
echo "📋 最近の承認 (最新3件):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
approved_files=($(ls -t exceptions/approved/*.csv 2>/dev/null | head -3))

if [ ${#approved_files[@]} -gt 0 ]; then
    for file in "${approved_files[@]}"; do
        info=$(tail -n +2 "$file" | grep -v "^#" | head -1)
        if [ -n "$info" ]; then
            app_id=$(echo "$info" | cut -d',' -f1)
            software=$(echo "$info" | cut -d',' -f4)
            version=$(echo "$info" | cut -d',' -f6)
            echo "  • $app_id - $software (v$version)"
        fi
    done
else
    echo "  承認済み申請なし"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                        クイックアクセス                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "  ./dashboard.sh          - メインダッシュボード"
echo "  ./demo.sh               - システムデモ"
echo "  ./commands.sh           - コマンド集"
echo "  ./system_status.sh      - 詳細状態確認"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
