#!/bin/bash

#######################################
# クイック審査（完全自動）
#######################################

REQUESTS_DIR="exceptions/requests"
REPORTS_DIR="exceptions/reports"
APPROVED_DIR="exceptions/approved"

mkdir -p "${REPORTS_DIR}" "${APPROVED_DIR}"

echo "======================================"
echo "⚡ クイック審査モード"
echo "======================================"
echo ""

# アーカイブからCSVを復元
if [ -d "exceptions/archived" ]; then
    archived_files=($(find "exceptions/archived" -name "*.csv" -type f))
    if [ ${#archived_files[@]} -gt 0 ]; then
        echo "📦 アーカイブからCSVを復元します..."
        for file in "${archived_files[@]}"; do
            cp "$file" "${REQUESTS_DIR}/"
            echo "  ✅ 復元: $(basename "$file")"
        done
        echo ""
    fi
fi

csv_files=($(find "${REQUESTS_DIR}" -name "*.csv" -type f))

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "❌ 申請CSVが見つかりません"
    exit 0
fi

echo "📋 処理対象: ${#csv_files[@]} ファイル"
echo ""

for csv_file in "${csv_files[@]}"; do
    echo "======================================"
    echo "📄 処理中: $(basename "$csv_file")"
    echo "======================================"
    echo ""
    
    line_num=0
    while IFS=',' read -r app_id app_date applicant software_name repo_url version purpose reason deadline notes
    do
        line_num=$((line_num + 1))
        
        # ヘッダーと空行をスキップ
        if [ $line_num -eq 1 ] || [ -z "$app_id" ]; then
            continue
        fi
        
        echo "申請ID: $app_id"
        echo "ソフトウェア: $software_name (v$version)"
        echo "申請者: $applicant"
        echo ""
        echo "🔍 審査実行中..."
        
        # 審査実行
        if [ -n "$repo_url" ] && [ -n "$software_name" ]; then
            ./software_audit.sh "$software_name" "$repo_url"
            
            # レポート検索
            latest_report=$(ls -t audit_reports/audit_${software_name}_*.txt 2>/dev/null | head -1)
            
            if [ -f "$latest_report" ]; then
                # レポートコピー
                report_name="${app_id}_$(basename "$latest_report")"
                cp "$latest_report" "${REPORTS_DIR}/${report_name}"
                
                echo ""
                echo "✅ レポート保存: ${report_name}"
                
                # レポートのサマリーを表示
                echo ""
                echo "--- 審査結果サマリー ---"
                grep -E "(判定結果|総合評価|Critical|High|Medium)" "$latest_report" | head -10
                echo ""
                
                # 自動承認
                approved_file="${APPROVED_DIR}/$(basename "$csv_file" .csv)_${app_id}.csv"
                echo "申請ID,申請日,申請者,ソフトウェア名,GitHubリポジトリURL,バージョン,利用目的,例外理由,承認期限,備考" > "$approved_file"
                echo "$app_id,$app_date,$applicant,$software_name,$repo_url,$version,$purpose,$reason,$deadline,$notes" >> "$approved_file"
                echo "# 承認日時: $(date '+%Y-%m-%d %H:%M:%S')" >> "$approved_file"
                echo "# 審査レポート: ${report_name}" >> "$approved_file"
                echo "# 自動承認" >> "$approved_file"
                
                echo "✅ 承認完了"
            else
                echo "⚠️  レポート未生成"
            fi
        else
            echo "❌ データ不正"
        fi
        
        echo ""
    done < "$csv_file"
    
    # アーカイブ
    mkdir -p exceptions/archived
    mv "$csv_file" exceptions/archived/
    echo "📦 アーカイブ: $(basename "$csv_file")"
    echo ""
done

echo "======================================"
echo "✅ 全審査完了"
echo "======================================"
echo ""
echo "📊 結果:"
approved_count=$(ls -1 "${APPROVED_DIR}"/*.csv 2>/dev/null | wc -l)
reports_count=$(ls -1 "${REPORTS_DIR}"/*.txt 2>/dev/null | wc -l)
echo "  承認: ${approved_count} 件"
echo "  レポート: ${reports_count} 件"
echo ""
