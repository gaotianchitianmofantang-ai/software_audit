#!/bin/bash

echo "======================================"
echo "ファイル存在確認"
echo "======================================"

files=(
    "README.md"
    "requirements.txt"
    ".gitignore"
    "software_audit.sh"
    "check_jvn.py"
    "check_updates.py"
    "check_rate_limit.py"
    "batch_audit.sh"
    "generate_summary.py"
    "setup_cron.sh"
    "software_list.txt"
)

all_ok=true

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (見つかりません)"
        all_ok=false
    fi
done

echo ""
echo "ディレクトリ:"
for dir in "audit_reports" "logs"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/"
    else
        echo "❌ $dir/ (見つかりません)"
        all_ok=false
    fi
done

echo ""
echo "======================================"
if $all_ok; then
    echo "結果: ✅ すべてのファイルが揃っています"
else
    echo "結果: ⚠️  一部のファイルが不足しています"
fi
echo "======================================"
