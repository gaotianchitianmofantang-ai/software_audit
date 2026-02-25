#!/bin/bash

echo "======================================"
echo "📚 よく使うコマンド集"
echo "======================================"
echo ""
echo "基本操作:"
echo "  ./dashboard.sh                      # ダッシュボード起動"
echo "  ./system_status.sh                  # システム状態確認"
echo ""
echo "監査実行:"
echo "  ./software_audit.sh <名前> <URL>    # 個別ソフトウェア監査"
echo "  ./quick_audit.sh                    # 例外申請一括審査"
echo ""
echo "例外申請:"
echo "  ./manage_exception_csv.sh           # 新規申請作成"
echo "  ./audit_exception_requests.sh       # 対話式審査"
echo ""
echo "結果確認:"
echo "  ./show_results.sh                   # 承認結果表示"
echo "  ./view_report.sh                    # レポート表示"
echo ""
echo "管理:"
echo "  ./approve_to_whitelist.sh           # ホワイトリスト追加"
echo "  cat software_whitelist.txt          # ホワイトリスト表示"
echo ""
echo "======================================"
echo ""

# メニュー
echo "コマンドを実行しますか？"
echo ""
echo "  [1] ダッシュボード起動"
echo "  [2] システム状態確認"
echo "  [3] 監査実行（requests）"
echo "  [4] ホワイトリスト表示"
echo "  [5] 全テスト実行"
echo "  [0] 終了"
echo ""
echo -n "選択 [0-5]: "

read choice

case $choice in
    1)
        ./dashboard.sh
        ;;
    2)
        ./system_status.sh
        ;;
    3)
        ./software_audit.sh "requests" "https://github.com/psf/requests"
        ;;
    4)
        echo ""
        cat software_whitelist.txt
        echo ""
        ;;
    5)
        ./full_test.sh
        ;;
    0)
        echo "終了します"
        exit 0
        ;;
    *)
        echo "無効な選択"
        ;;
esac
