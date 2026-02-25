#!/bin/bash
set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ディレクトリ設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_DIR="${SCRIPT_DIR}/csv_data"
REPORTS_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "${CSV_DIR}" "${REPORTS_DIR}"

echo -e "${BLUE}ソフトウェアセキュリティ審査ツール${NC}\n"

# 引数チェック
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}使い方: ./audit_software_security.sh [CSVファイル名]${NC}"
    exit 1
fi

CSV_FILE="$1"
CSV_PATH="${CSV_DIR}/${CSV_FILE}"

if [ ! -f "${CSV_PATH}" ]; then
    echo -e "${RED}エラー: CSVファイルが見つかりません${NC}"
    exit 1
fi

BASENAME="${CSV_FILE%.csv}"
REPORT_FILE="${REPORTS_DIR}/審査レポート_${BASENAME}_${TIMESTAMP}.md"

# CSV情報抽出（外部スクリプト呼び出し）
echo -e "${BLUE}[1] CSV情報を抽出中...${NC}"
export CSV_PATH
python3 "${SCRIPT_DIR}/extract_csv.py" > /tmp/sw_info.json

if [ $? -ne 0 ]; then
    echo -e "${RED}エラー: CSV抽出失敗${NC}"
    exit 1
fi

# 情報取得
SOFTWARE_NAME=$(python3 -c "import sys, json; print(json.load(open('/tmp/sw_info.json')).get('ソフトウェア名', ''))")
IS_PAID=$(python3 -c "import sys, json; print(json.load(open('/tmp/sw_info.json')).get('有償無償', ''))")

echo -e "${GREEN}✓ ソフトウェア名: ${SOFTWARE_NAME}${NC}"
echo -e "${GREEN}✓ 有償/無償: ${IS_PAID}${NC}\n"

# レポート生成（外部スクリプト呼び出し）
echo -e "${BLUE}[2] レポート生成中...${NC}"
python3 "${SCRIPT_DIR}/generate_report.py" /tmp/sw_info.json "${REPORT_FILE}"

echo -e "\n${GREEN}✓ 審査レポートを生成しました${NC}"
echo -e "出力先: ${REPORT_FILE}\n"

rm -f /tmp/sw_info.json
