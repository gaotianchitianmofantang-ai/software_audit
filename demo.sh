#!/bin/bash

echo "======================================"
echo "🎬 ソフトウェア監査システム デモ"
echo "======================================"
echo ""
echo "このデモでは以下を実行します:"
echo "  1. 人気ソフトウェアの監査"
echo "  2. 例外申請の自動審査"
echo "  3. ホワイトリストへの登録"
echo "  4. システム状態の確認"
echo ""
read -p "Enterキーを押して開始..."

# ステップ1
clear
echo "======================================"
echo "📝 ステップ1: ソフトウェア監査実行"
echo "======================================"
echo ""
echo "requests (HTTP通信ライブラリ) を監査します..."
echo ""
sleep 2

./software_audit.sh "requests" "https://github.com/psf/requests"

echo ""
read -p "Enterキーで次へ..."

# ステップ2
clear
echo "======================================"
echo "📝 ステップ2: 例外申請の自動審査"
echo "======================================"
echo ""
echo "既存の例外申請を審査します..."
echo ""
sleep 2

if [ -d "exceptions/archived" ]; then
    archived_count=$(find exceptions/archived/ -name "*.csv" -type f 2>/dev/null | wc -l)
    if [ $archived_count -gt 0 ]; then
        cp exceptions/archived/*.csv exceptions/requests/ 2>/dev/null
        ./quick_audit.sh
    else
        echo "申請CSVが見つかりません（スキップ）"
    fi
else
    echo "アーカイブディレクトリが見つかりません（スキップ）"
fi

echo ""
read -p "Enterキーで次へ..."

# ステップ3
clear
echo "======================================"
echo "📝 ステップ3: ホワイトリスト登録"
echo "======================================"
echo ""
echo "承認済みソフトウェアをホワイトリストに追加..."
echo ""
sleep 2

./approve_to_whitelist.sh

echo ""
read -p "Enterキーで次へ..."

# ステップ4
clear
echo "======================================"
echo "📝 ステップ4: システム状態確認"
echo "======================================"
echo ""
sleep 2

./system_status.sh

echo ""
echo "======================================"
echo "✅ デモ完了"
echo "======================================"
echo ""
echo "ダッシュボードを起動するには:"
echo "  ./dashboard.sh"
echo ""
