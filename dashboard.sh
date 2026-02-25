#!/bin/bash

# カラーコード
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}║           ${GREEN}ソフトウェア監査システム ダッシュボード${CYAN}           ║${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# システム統計
requests_count=$(find exceptions/requests/ -name "*.csv" -type f 2>/dev/null | wc -l)
approved_count=$(find exceptions/approved/ -name "*.csv" -type f 2>/dev/null | wc -l)
rejected_count=$(find exceptions/rejected/ -name "*.csv" -type f 2>/dev/null | wc -l)
reports_count=$(find exceptions/reports/ -name "*.txt" -type f 2>/dev/null | wc -l)
archived_count=$(find exceptions/archived/ -name "*.csv" -type f 2>/dev/null | wc -l)
audit_reports_count=$(find audit_reports/ -name "*.txt" -type f 2>/dev/null | wc -l)
whitelist_count=$(grep -v "^#" software_whitelist.txt 2>/dev/null | grep -c "^" || echo 0)

echo -e "${BLUE}📊 システム統計${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-25s %3d 件\n" "申請中:" "$requests_count"
printf "%-25s ${GREEN}%3d 件${NC}\n" "承認済み:" "$approved_count"
printf "%-25s ${RED}%3d 件${NC}\n" "却下:" "$rejected_count"
printf "%-25s %3d 件\n" "例外レポート:" "$reports_count"
printf "%-25s %3d 件\n" "アーカイブ:" "$archived_count"
printf "%-25s %3d 件\n" "全監査レポート:" "$audit_reports_count"
printf "%-25s ${GREEN}%3d 件${NC}\n" "ホワイトリスト登録:" "$whitelist_count"
echo ""

# 最近の承認
echo -e "${BLUE}📋 最近の承認 (最新5件)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $approved_count -gt 0 ]; then
    count=0
    for file in $(ls -t exceptions/approved/*.csv 2>/dev/null | head -5); do
        count=$((count + 1))
        # CSVから情報を抽出
        info=$(tail -n +2 "$file" | grep -v "^#" | head -1)
        if [ -n "$info" ]; then
            app_id=$(echo "$info" | cut -d',' -f1)
            software=$(echo "$info" | cut -d',' -f4)
            version=$(echo "$info" | cut -d',' -f6)
            
            # 承認日時を取得
            approval_date=$(grep "承認日時" "$file" | sed 's/.*: //')
            
            echo -e "${GREEN}[$count]${NC} $app_id"
            echo "    ソフトウェア: $software (v$version)"
            echo "    承認日時: $approval_date"
            echo ""
        fi
    done
else
    echo "  承認済み申請はありません"
    echo ""
fi

# ホワイトリスト
echo -e "${BLUE}✅ ホワイトリスト登録ソフトウェア${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "software_whitelist.txt" ] && [ $whitelist_count -gt 0 ]; then
    grep -v "^#" software_whitelist.txt | grep "^" | while IFS=',' read -r name repo version status date; do
        echo -e "  ${GREEN}✓${NC} $name (v$version) - 登録日: $date"
    done
else
    echo "  登録なし"
fi
echo ""

# メニュー
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                        ${YELLOW}メニュー${CYAN}                               ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  [1] 新規申請を作成"
echo "  [2] 申請を審査（対話式）"
echo "  [3] 申請を審査（自動）"
echo "  [4] 結果を表示"
echo "  [5] レポートを表示"
echo "  [6] ホワイトリストに追加"
echo "  [7] CSV管理メニュー"
echo "  [8] システム状態詳細"
echo "  [9] ダッシュボード更新"
echo "  [0] 終了"
echo ""
echo -n "選択してください: "

read choice

case $choice in
    1)
        ./manage_exception_csv.sh
        ;;
    2)
        ./audit_exception_requests.sh
        ;;
    3)
        ./quick_audit.sh
        ;;
    4)
        ./show_results.sh
        ;;
    5)
        ./view_report.sh
        ;;
    6)
        ./approve_to_whitelist.sh
        ;;
    7)
        ./manage_exception_csv.sh
        ;;
    8)
        ./system_status.sh
        ;;
    9)
        ./dashboard.sh
        ;;
    0)
        echo ""
        echo "終了します"
        exit 0
        ;;
    *)
        echo ""
        echo "無効な選択です"
        sleep 2
        ./dashboard.sh
        ;;
esac
