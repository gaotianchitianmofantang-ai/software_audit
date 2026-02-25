#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_DIR="${SCRIPT_DIR}/csv_data"
REPORTS_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "${CSV_DIR}" "${REPORTS_DIR}"

echo "=========================================="
echo "Garoon ワークフロー審査ツール"
echo "=========================================="

CSV_FILE="$1"
CSV_PATH="${CSV_DIR}/${CSV_FILE}"

if [ ! -f "${CSV_PATH}" ]; then
    echo "エラー: CSVファイルが見つかりません"
    exit 1
fi

echo "処理対象: ${CSV_FILE}"
