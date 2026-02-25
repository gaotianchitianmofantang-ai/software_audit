#!/bin/bash
# ソフトウェアセキュリティ審査バッチ処理

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_DIR="${SCRIPT_DIR}/csv_data"
LOG_DIR="${SCRIPT_DIR}/logs"

mkdir -p "${LOG_DIR}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/batch_audit_${TIMESTAMP}.log"

echo "=====================================" | tee -a "${LOG_FILE}"
echo "ソフトウェアセキュリティ審査バッチ" | tee -a "${LOG_FILE}"
echo "実行日時: $(date '+%Y年%m月%d日 %H:%M:%S')" | tee -a "${LOG_FILE}"
echo "=====================================" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

# CSVファイルを順次処理
csv_count=0
success_count=0
error_count=0

for csv_file in "${CSV_DIR}"/*.csv; do
    if [ ! -f "${csv_file}" ]; then
        echo "CSVファイルが見つかりません: ${CSV_DIR}" | tee -a "${LOG_FILE}"
        exit 1
    fi
    
    csv_count=$((csv_count + 1))
    echo "[${csv_count}] 処理中: $(basename "${csv_file}")" | tee -a "${LOG_FILE}"
    
    if python3 "${SCRIPT_DIR}/auto_audit.py" "${csv_file}" >> "${LOG_FILE}" 2>&1; then
        success_count=$((success_count + 1))
        echo "  ✅ 成功" | tee -a "${LOG_FILE}"
    else
        error_count=$((error_count + 1))
        echo "  ❌ エラー" | tee -a "${LOG_FILE}"
    fi
    
    echo "" | tee -a "${LOG_FILE}"
done

echo "=====================================" | tee -a "${LOG_FILE}"
echo "処理完了" | tee -a "${LOG_FILE}"
echo "総数: ${csv_count}件" | tee -a "${LOG_FILE}"
echo "成功: ${success_count}件" | tee -a "${LOG_FILE}"
echo "エラー: ${error_count}件" | tee -a "${LOG_FILE}"
echo "=====================================" | tee -a "${LOG_FILE}"

echo ""
echo "ログファイル: ${LOG_FILE}"
