#!/bin/bash

# csv_data/ディレクトリ内の全CSVファイルを一括処理

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_DIR="${SCRIPT_DIR}/csv_data"
REPORTS_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SUMMARY_REPORT="${REPORTS_DIR}/summary_${TIMESTAMP}.txt"

# reportsディレクトリ作成
mkdir -p "${REPORTS_DIR}"

echo "=========================================="
echo "Garoon CSV 一括監査ツール"
echo "=========================================="
echo "処理ディレクトリ: ${CSV_DIR}"
echo "レポート保存先: ${REPORTS_DIR}"
echo ""

# CSVファイルのカウント
CSV_COUNT=$(find "${CSV_DIR}" -maxdepth 1 -name "*.csv" -type f | wc -l)

if [ ${CSV_COUNT} -eq 0 ]; then
    echo "エラー: ${CSV_DIR} にCSVファイルが見つかりません"
    exit 1
fi

echo "検出されたCSVファイル数: ${CSV_COUNT}件"
echo ""

# サマリーレポートのヘッダー
{
    echo "=========================================="
    echo "Garoon CSV 一括監査サマリー"
    echo "=========================================="
    echo "処理日時: $(date '+%Y/%m/%d %H:%M:%S')"
    echo "処理件数: ${CSV_COUNT}件"
    echo ""
} > "${SUMMARY_REPORT}"

# 処理カウンター
PROCESSED=0
SUCCESS=0
FAILED=0

# csv_data/内の全CSVファイルを処理
find "${CSV_DIR}" -maxdepth 1 -name "*.csv" -type f | sort | while read -r csv_file; do
    PROCESSED=$((PROCESSED + 1))
    FILENAME=$(basename "${csv_file}")
    REPORT_FILE="${REPORTS_DIR}/audit_${FILENAME%.csv}_${TIMESTAMP}.txt"
    
    echo "----------------------------------------"
    echo "[${PROCESSED}/${CSV_COUNT}] 処理中: ${FILENAME}"
    echo "----------------------------------------"
    
    # 個別レポート生成
    if ./garoon_csv_audit.sh "${FILENAME}" > "${REPORT_FILE}" 2>&1; then
        echo "✓ 完了: ${REPORT_FILE}"
        SUCCESS=$((SUCCESS + 1))
        
        # サマリーに追加
        {
            echo "----------------------------------------"
            echo "ファイル名: ${FILENAME}"
            echo "ステータス: ✓ 成功"
            echo "レポート: ${REPORT_FILE}"
            echo ""
        } >> "${SUMMARY_REPORT}"
    else
        echo "✗ エラー: ${FILENAME} の処理に失敗しました"
        FAILED=$((FAILED + 1))
        
        # サマリーに追加
        {
            echo "----------------------------------------"
            echo "ファイル名: ${FILENAME}"
            echo "ステータス: ✗ 失敗"
            echo ""
        } >> "${SUMMARY_REPORT}"
    fi
    
    echo ""
done

# 最終サマリー
{
    echo "=========================================="
    echo "処理結果"
    echo "=========================================="
    echo "総ファイル数: ${CSV_COUNT}"
    echo "成功: ${SUCCESS}"
    echo "失敗: ${FAILED}"
    echo ""
} >> "${SUMMARY_REPORT}"

echo "=========================================="
echo "一括処理完了"
echo "=========================================="
echo "サマリーレポート: ${SUMMARY_REPORT}"
echo ""

# サマリーレポートを表示
cat "${SUMMARY_REPORT}"
