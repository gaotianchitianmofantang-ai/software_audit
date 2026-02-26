#!/bin/bash
# WindowsフォルダからCSVを取り込んで審査実行

WINDOWS_CSV_DIR="/mnt/c/Users/takahata.t250/software_audit"
WSL_PROJECT_DIR="$HOME/software_audit"

echo "=========================================="
echo "ソフトウェア審査システム"
echo "=========================================="
echo ""

# プロジェクトディレクトリに移動
cd "$WSL_PROJECT_DIR" || exit 1

# WindowsフォルダのCSVファイルを確認
echo "📂 Windowsフォルダ内のCSVファイル:"
ls -lh "$WINDOWS_CSV_DIR"/*.csv 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ CSVファイルが見つかりません: $WINDOWS_CSV_DIR"
    exit 1
fi

echo ""
echo "🔄 CSVファイルをWSLにコピー中..."

# CSVファイルをコピー
cp "$WINDOWS_CSV_DIR"/*.csv data/pending/ 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ コピー完了"
else
    echo "❌ コピー失敗"
    exit 1
fi

echo ""
echo "📋 審査待ちCSVファイル:"
ls -lh data/pending/*.csv

echo ""
echo "🔍 審査を開始します..."
echo ""

# 審査実行
python workflow_audit.py

echo ""
echo "=========================================="
echo "✅ 処理完了"
echo "=========================================="
echo ""
echo "📊 結果を確認:"
echo "  承認: data/approved/"
echo "  却下: data/rejected/"
echo "  要手動審査: data/manual_review/"
echo "  レポート: reports/"
echo ""

# 結果をWindowsフォルダにもコピー（オプション）
read -p "結果をWindowsフォルダにコピーしますか? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$WINDOWS_CSV_DIR/results"
    cp -r data/approved "$WINDOWS_CSV_DIR/results/"
    cp -r data/rejected "$WINDOWS_CSV_DIR/results/"
    cp -r data/manual_review "$WINDOWS_CSV_DIR/results/"
    cp -r reports "$WINDOWS_CSV_DIR/results/"
    echo "✅ 結果をコピーしました: $WINDOWS_CSV_DIR/results/"
fi

# レポートをブラウザで開く
if ls reports/*.html 1> /dev/null 2>&1; then
    LATEST_REPORT=$(ls -t reports/*.html | head -1)
    echo ""
    read -p "HTMLレポートを開きますか? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Windowsのデフォルトブラウザで開く
        cmd.exe /c start "$(wslpath -w "$LATEST_REPORT")"
    fi
fi
