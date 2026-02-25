#!/bin/bash

echo "======================================"
echo "🔍 ソフトウェア監査システムの状態"
echo "======================================"
echo ""

# 1. ディレクトリ構成
echo "📁 ディレクトリ構成:"
echo ""
tree exceptions/ -L 2 2>/dev/null || {
    echo "exceptions/"
    find exceptions/ -type d | sed 's|^|  |' | sort
}

echo ""
echo "======================================"

# 2. 統計情報
echo "📊 統計情報:"
echo ""

requests_count=$(find exceptions/requests/ -name "*.csv" -type f 2>/dev/null | wc -l)
approved_count=$(find exceptions/approved/ -name "*.csv" -type f 2>/dev/null | wc -l)
rejected_count=$(find exceptions/rejected/ -name "*.csv" -type f 2>/dev/null | wc -l)
reports_count=$(find exceptions/reports/ -name "*.txt" -type f 2>/dev/null | wc -l)
archived_count=$(find exceptions/archived/ -name "*.csv" -type f 2>/dev/null | wc -l)
audit_reports_count=$(find audit_reports/ -name "*.txt" -type f 2>/dev/null | wc -l)

echo "  申請中:         $requests_count 件"
echo "  承認済み:       $approved_count 件"
echo "  却下:           $rejected_count 件"
echo "  例外レポート:   $reports_count 件"
echo "  アーカイブ:     $archived_count 件"
echo "  全監査レポート: $audit_reports_count 件"

echo ""
echo "======================================"

# 3. ファイル一覧
echo "📂 ファイル一覧:"
echo ""

if [ $approved_count -gt 0 ]; then
    echo "✅ 承認済み申請:"
    ls -1 exceptions/approved/*.csv 2>/dev/null | while read file; do
        echo "  - $(basename "$file")"
    done
    echo ""
fi

if [ $reports_count -gt 0 ]; then
    echo "📄 例外審査レポート:"
    ls -1 exceptions/reports/*.txt 2>/dev/null | while read file; do
        echo "  - $(basename "$file")"
    done
    echo ""
fi

if [ $archived_count -gt 0 ]; then
    echo "📦 アーカイブ済みCSV:"
    ls -1 exceptions/archived/*.csv 2>/dev/null | while read file; do
        echo "  - $(basename "$file")"
    done
    echo ""
fi

echo "======================================"

# 4. 承認内容サマリー
if [ $approved_count -gt 0 ]; then
    echo ""
    echo "📋 承認内容サマリー:"
    echo ""
    
    for file in exceptions/approved/*.csv; do
        if [ -f "$file" ]; then
            echo "---"
            echo "📄 $(basename "$file")"
            
            # CSVから情報を抽出（ヘッダー行を除く）
            tail -n +2 "$file" | grep -v "^#" | while IFS=',' read -r app_id app_date applicant software_name repo_url version rest; do
                if [ -n "$app_id" ]; then
                    echo "  申請ID:      $app_id"
                    echo "  ソフトウェア: $software_name (v$version)"
                    echo "  申請者:      $applicant"
                    echo "  リポジトリ:  $repo_url"
                fi
            done
            
            # 承認日時と審査レポートを表示
            grep "^#" "$file" | sed 's/^# /  /'
            echo ""
        fi
    done
fi

echo "======================================"
echo ""
echo "🛠️  利用可能なコマンド:"
echo "  ./audit_exception_requests.sh    # 対話式審査"
echo "  ./quick_audit.sh                 # 自動審査"
echo "  ./show_results.sh                # 結果表示"
echo "  ./view_report.sh                 # レポート表示"
echo "  ./manage_exception_csv.sh        # CSV管理"
echo ""
echo "======================================"
