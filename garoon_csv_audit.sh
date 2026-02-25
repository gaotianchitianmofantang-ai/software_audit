#!/bin/bash

# Garoon CSVファイルを処理して例外申請を監査するスクリプト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_DIR="${SCRIPT_DIR}/csv_data"
EXCEPTIONS_DIR="${SCRIPT_DIR}/exceptions"
ARCHIVE_DIR="${EXCEPTIONS_DIR}/archived"
PYTHON_SCRIPT="${SCRIPT_DIR}/process_garoon_csv.py"

# 引数チェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 <CSVファイル名>"
    echo "例: $0 workflow_申請データ_20260206.csv"
    exit 1
fi

CSV_FILE="$1"

# ファイルパスの解決
if [ -f "${CSV_FILE}" ]; then
    CSV_PATH="${CSV_FILE}"
elif [ -f "${CSV_DIR}/${CSV_FILE}" ]; then
    CSV_PATH="${CSV_DIR}/${CSV_FILE}"
else
    echo "エラー: ファイルが見つかりません: ${CSV_FILE}"
    exit 1
fi

echo "==========================="
echo "Garoon CSV 監査ツール"
echo "==========================="
echo "処理ファイル: ${CSV_PATH}"
echo ""

# Pythonスクリプトを実行
if [ -f "${PYTHON_SCRIPT}" ]; then
    python3 "${PYTHON_SCRIPT}" "${CSV_PATH}"
else
    echo "エラー: ${PYTHON_SCRIPT} が見つかりません"
    exit 1
fi

echo ""
echo "処理完了"
