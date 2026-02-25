#!/bin/bash

#######################################
# 例外ソフトウェア申請審査バッチ
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUESTS_DIR="${SCRIPT_DIR}/exceptions/requests"
APPROVED_DIR="${SCRIPT_DIR}/exceptions/approved"
REJECTED_DIR="${SCRIPT_DIR}/exceptions/rejected"
REPORTS_DIR="${SCRIPT_DIR}/exceptions/reports"

# カラーコード
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ディレクトリ作成
mkdir -p "${REQUESTS_DIR}" "${APPROVED_DIR}" "${REJECTED_DIR}" "${REPORTS_DIR}"

echo "======================================"
echo "  例外ソフトウェア申請審査バッチ"
echo "======================================"
echo ""

# CSVファイルを検索
csv_files=($(find "${REQUESTS_DIR}" -name "*.csv" -type f))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo -e "${YELLOW}申請CSVファイルが見つかりません。${NC}"
    echo ""
    echo "📝 手順:"
    echo "  1. exceptions/exception_template.csv をコピー"
    echo "  2. 必要事項を記入"
    echo "  3. exceptions/requests/ に配置"
    echo "  4. このスクリプトを再実行"
    exit 0
fi

echo -e "${GREEN}申請ファイル数: ${#csv_files[@]}${NC}"
echo ""

# 各CSVファイルを処理
for csv_file in "${csv_files[@]}"; do
    echo "======================================"
    echo "📄 ファイル: $(basename "$csv_file")"
    echo "======================================"
    echo ""
    
    # ヘッダー行をスキップしてデータを読み込む
    line_num=0
    while IFS=',' read -r app_id app_date applicant software_name repo_url version purpose reason deadline notes
    do
        line_num=$((line_num + 1))
        
        # ヘッダー行をスキップ
        if [ $line_num -eq 1 ]; then
            continue
        fi
        
        # 空行をスキップ
        if [ -z "$app_id" ]; then
            continue
        fi
        
        echo "----------------------------------------"
        echo -e "${BLUE}申請ID:${NC} $app_id"
        echo -e "${BLUE}申請日:${NC} $app_date"
        echo -e "${BLUE}申請者:${NC} $applicant"
        echo -e "${BLUE}ソフトウェア:${NC} $software_name (v$version)"
        echo -e "${BLUE}リポジトリ:${NC} $repo_url"
        echo -e "${BLUE}利用目的:${NC} $purpose"
        echo -e "${BLUE}例外理由:${NC} $reason"
        echo -e "${BLUE}承認期限:${NC} $deadline"
        if [ -n "$notes" ]; then
            echo -e "${BLUE}備考:${NC} $notes"
        fi
        echo "----------------------------------------"
        echo ""
        
        # 審査実行の確認
        echo -n "この申請を審査しますか？ [y/N]: "
        read -r response
        
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo -e "${YELLOW}スキップしました${NC}"
            echo ""
            continue
        fi
        
        # 審査実行
        echo ""
        echo "🔍 審査を開始します..."
        echo ""
        
        if [ -n "$repo_url" ] && [ -n "$software_name" ]; then
            # software_audit.sh を実行
            ./software_audit.sh "$software_name" "$repo_url"
            audit_result=$?
            
            # レポートファイルを探す
            latest_report=$(ls -t audit_reports/audit_${software_name// /_}_*.txt 2>/dev/null | head -1)
            
            if [ -f "$latest_report" ]; then
                # レポートを例外用ディレクトリにコピー
                report_name="${app_id}_$(basename "$latest_report")"
                cp "$latest_report" "${REPORTS_DIR}/${report_name}"
                echo ""
                echo -e "${GREEN}✅ レポートを保存: ${report_name}${NC}"
                echo ""
                
                # レポート内容を表示
                echo "--- 審査結果サマリー ---"
                grep -E "(判定結果|総合評価|警告|推奨事項)" "$latest_report" | head -10
                echo ""
            fi
            
            # 承認/却下の判断
            echo "審査結果を確認してください。"
            echo ""
            echo "[1] 承認"
            echo "[2] 却下"
            echo "[3] 保留（スキップ）"
            echo -n "選択してください: "
            read -r decision
            
            case $decision in
                1)
                    # 承認処理
                    approved_file="${APPROVED_DIR}/$(basename "$csv_file" .csv)_${app_id}.csv"
                    echo "$app_id,$app_date,$applicant,$software_name,$repo_url,$version,$purpose,$reason,$deadline,$notes" > "$approved_file"
                    echo "# 承認日時: $(date '+%Y-%m-%d %H:%M:%S')" >> "$approved_file"
                    echo "# 審査レポート: ${report_name}" >> "$approved_file"
                    echo ""
                    echo -e "${GREEN}✅ 申請 $app_id を承認しました${NC}"
                    ;;
                2)
                    # 却下処理
                    echo -n "却下理由を入力してください: "
                    read -r reject_reason
                    rejected_file="${REJECTED_DIR}/$(basename "$csv_file" .csv)_${app_id}.csv"
                    echo "$app_id,$app_date,$applicant,$software_name,$repo_url,$version,$purpose,$reason,$deadline,$notes" > "$rejected_file"
                    echo "# 却下日時: $(date '+%Y-%m-%d %H:%M:%S')" >> "$rejected_file"
                    echo "# 却下理由: $reject_reason" >> "$rejected_file"
                    echo ""
                    echo -e "${RED}❌ 申請 $app_id を却下しました${NC}"
                    ;;
                3)
                    echo -e "${YELLOW}⏸️  保留しました${NC}"
                    ;;
                *)
                    echo -e "${YELLOW}無効な選択です。保留します。${NC}"
                    ;;
            esac
        else
            echo -e "${RED}❌ ソフトウェア名またはリポジトリURLが不正です${NC}"
        fi
        
        echo ""
        echo ""
    done < "$csv_file"
    
    # 処理済みファイルの移動確認
    echo "======================================"
    echo "ファイル $(basename "$csv_file") の処理が完了しました。"
    echo -n "このファイルをアーカイブしますか？ [y/N]: "
    read -r archive_response
    
    if [ "$archive_response" = "y" ] || [ "$archive_response" = "Y" ]; then
        mkdir -p "${SCRIPT_DIR}/exceptions/archived"
        mv "$csv_file" "${SCRIPT_DIR}/exceptions/archived/"
        echo -e "${GREEN}✅ アーカイブしました${NC}"
    fi
    
    echo ""
done

echo "======================================"
echo "  全ての申請の処理が完了しました"
echo "======================================"
echo ""
echo "📊 結果:"

# 修正: パイプを削除して直接実行
approved_count=$(ls -1 "${APPROVED_DIR}"/*.csv 2>/dev/null | wc -l)
rejected_count=$(ls -1 "${REJECTED_DIR}"/*.csv 2>/dev/null | wc -l)
reports_count=$(ls -1 "${REPORTS_DIR}"/*.txt 2>/dev/null | wc -l)

echo "  承認: ${approved_count} 件"
echo "  却下: ${rejected_count} 件"
echo "  レポート: ${reports_count} 件"
echo ""
