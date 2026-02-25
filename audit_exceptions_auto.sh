#!/bin/bash

#######################################
# 例外ソフトウェア申請審査（自動実行版）
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUESTS_DIR="${SCRIPT_DIR}/exceptions/requests"
REPORTS_DIR="${SCRIPT_DIR}/exceptions/reports"

mkdir -p "${REPORTS_DIR}"

echo "======================================"
echo "  例外申請審査（自動実行モード）"
echo "======================================"
echo ""

csv_files=($(find "${REQUESTS_DIR}" -name "*.csv" -type f))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "申請CSVファイルが見つかりません。"
    exit 0
fi

total=0
success=0
failed=0

for csv_file in "${csv_files[@]}"; do
    echo "処理中: $(basename "$csv_file")"
    
    line_num=0
    while IFS=',' read -r app_id app_date applicant software_name repo_url version purpose reason deadline notes
    do
        line_num=$((line_num + 1))
        
        if [ $line_num -eq 1 ] || [ -z "$app_id" ]; then
            continue
        fi
        
        total=$((total + 1))
        
        echo "  [$total] $app_id: $software_name"
        
        if [ -n "$repo_url" ] && [ -n "$software_name" ]; then
            ./software_audit.sh "$software_name" "$repo_url" > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                latest_report=$(ls -t audit_reports/audit_${software_name// /_}_*.txt 2>/dev/null | head -1)
                
                if [ -f "$latest_report" ]; then
                    cp "$latest_report" "${REPORTS_DIR}/${app_id}_$(basename "$latest_report")"
                    echo "      ✅ 完了"
                    success=$((success + 1))
                else
                    echo "      ⚠️  レポート未生成"
                    failed=$((failed + 1))
                fi
            else
                echo "      ❌ 審査失敗"
                failed=$((failed + 1))
            fi
        else
            echo "      ❌ データ不正"
            failed=$((failed + 1))
        fi
    done < "$csv_file"
done

echo ""
echo "======================================"
echo "処理完了"
echo "======================================"
echo "  合計: $total"
echo "  成功: $success"
echo "  失敗: $failed"
echo ""
