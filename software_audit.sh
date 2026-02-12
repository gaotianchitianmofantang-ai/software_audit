#!/bin/bash
set -e

if [ $# -lt 1 ]; then
    echo "使用方法: $0 <ソフトウェア名> [GitHub URL]"
    exit 1
fi

SOFTWARE_NAME="$1"
GITHUB_URL="${2:-}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="audit_reports"
REPORT_FILE="${REPORT_DIR}/audit_${SOFTWARE_NAME// /_}_${TIMESTAMP}.txt"

mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" << REPORT_EOF
================================================================================
ソフトウェア審査レポート
================================================================================
対象ソフトウェア: ${SOFTWARE_NAME}
審査実施日時: $(date "+%Y年%m月%d日 %H:%M:%S")
審査担当: $(whoami)
================================================================================

REPORT_EOF

echo "[INFO] 審査を開始します: ${SOFTWARE_NAME}"
OVERALL_PASS=true

echo ""
echo "[1/2] JVNDBで脆弱性を確認中..."
echo "" >> "$REPORT_FILE"
echo "■ 1. JVNDBチェック" >> "$REPORT_FILE"
echo "----------------------------------------" >> "$REPORT_FILE"

if python3 check_jvn.py "$SOFTWARE_NAME" >> "$REPORT_FILE" 2>&1; then
    echo "  ✅ 合格"
else
    echo "  ❌ 不合格"
    OVERALL_PASS=false
fi

echo ""
echo "[2/2] 更新頻度を確認中..."
echo "" >> "$REPORT_FILE"
echo "■ 2. 更新頻度チェック" >> "$REPORT_FILE"
echo "----------------------------------------" >> "$REPORT_FILE"

if [ -n "$GITHUB_URL" ]; then
    if python3 check_updates.py "$GITHUB_URL" >> "$REPORT_FILE" 2>&1; then
        echo "  ✅ 合格"
    else
        echo "  ❌ 不合格"
        OVERALL_PASS=false
    fi
else
    echo "  ⚠️  GitHub URLが指定されていません" | tee -a "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "================================================================================" >> "$REPORT_FILE"
echo "総合判定: $([ "$OVERALL_PASS" = true ] && echo "✅ 合格" || echo "❌ 不合格")" >> "$REPORT_FILE"
echo "================================================================================" >> "$REPORT_FILE"

echo ""
echo "=========================================="
if $OVERALL_PASS; then
    echo "自動チェック: 合格 ✅"
else
    echo "自動チェック: 不合格 ❌"
fi
echo "=========================================="
echo ""
echo "レポート保存先: ${REPORT_FILE}"

exit 0
