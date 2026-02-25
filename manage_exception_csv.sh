#!/bin/bash

#######################################
# 例外申請CSV管理スクリプト
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/exceptions/exception_template.csv"
REQUESTS_DIR="${SCRIPT_DIR}/exceptions/requests"

show_menu() {
    echo "======================================"
    echo "  例外申請CSV管理"
    echo "======================================"
    echo ""
    echo "[1] 新規申請CSVを作成"
    echo "[2] 申請中のCSV一覧"
    echo "[3] 承認済み一覧"
    echo "[4] 却下済み一覧"
    echo "[5] テンプレートを開く"
    echo "[0] 終了"
    echo ""
    echo -n "選択: "
}

create_new_request() {
    echo ""
    echo "新規申請CSVを作成します"
    echo ""
    echo -n "ファイル名（拡張子なし）: "
    read -r filename
    
    if [ -z "$filename" ]; then
        echo "キャンセルしました"
        return
    fi
    
    new_file="${REQUESTS_DIR}/${filename}.csv"
    
    if [ -f "$new_file" ]; then
        echo "既に存在します: $new_file"
        return
    fi
    
    # 申請IDを自動生成
    app_id="EX-$(date '+%Y%m%d%H%M%S')"
    app_date=$(date '+%Y-%m-%d')
    
    # テンプレートをコピー
    cp "$TEMPLATE" "$new_file"
    
    # ヘッダー行のみ残して、サンプルデータを削除
    head -n 1 "$TEMPLATE" > "$new_file"
    
    # 空行を追加（編集用）
    echo "$app_id,$app_date,,,,,,,,," >> "$new_file"
    
    echo ""
    echo "✅ 作成しました: $new_file"
    echo "   申請ID: $app_id"
    echo ""
    echo "次のコマンドで編集してください:"
    echo "  nano $new_file"
    echo "  または"
    echo "  vi $new_file"
    echo ""
}

list_requests() {
    echo ""
    echo "======================================"
    echo "申請中のCSV"
    echo "======================================"
    
    if [ ! -d "$REQUESTS_DIR" ]; then
        echo "ディレクトリが見つかりません"
        return
    fi
    
    csv_files=($(find "${REQUESTS_DIR}" -name "*.csv" -type f))
    
    if [ ${#csv_files[@]} -eq 0 ]; then
        echo "申請中のCSVはありません"
        return
    fi
    
    for csv_file in "${csv_files[@]}"; do
        echo ""
        echo "📄 $(basename "$csv_file")"
        
        line_num=0
        while IFS=',' read -r app_id app_date applicant software_name repo_url version purpose reason deadline notes
        do
            line_num=$((line_num + 1))
            
            if [ $line_num -eq 1 ] || [ -z "$app_id" ]; then
                continue
            fi
            
            echo "  ├─ 申請ID: $app_id"
            echo "  ├─ ソフトウェア: $software_name (v$version)"
            echo "  ├─ 申請者: $applicant"
            echo "  └─ 期限: $deadline"
        done < "$csv_file"
    done
    echo ""
}

list_approved() {
    echo ""
    echo "======================================"
    echo "承認済み"
    echo "======================================"
    
    approved_dir="${SCRIPT_DIR}/exceptions/approved"
    
    if [ ! -d "$approved_dir" ]; then
        echo "ディレクトリが見つかりません"
        return
    fi
    
    csv_files=($(find "${approved_dir}" -name "*.csv" -type f))
    
    if [ ${#csv_files[@]} -eq 0 ]; then
        echo "承認済みの申請はありません"
        return
    fi
    
    for csv_file in "${csv_files[@]}"; do
        echo ""
        echo "✅ $(basename "$csv_file")"
        head -n 1 "$csv_file"
        tail -n +2 "$csv_file" | grep -v "^#"
    done
    echo ""
}

list_rejected() {
    echo ""
    echo "======================================"
    echo "却下済み"
    echo "======================================"
    
    rejected_dir="${SCRIPT_DIR}/exceptions/rejected"
    
    if [ ! -d "$rejected_dir" ]; then
        echo "ディレクトリが見つかりません"
        return
    fi
    
    csv_files=($(find "${rejected_dir}" -name "*.csv" -type f))
    
    if [ ${#csv_files[@]} -eq 0 ]; then
        echo "却下済みの申請はありません"
        return
    fi
    
    for csv_file in "${csv_files[@]}"; do
        echo ""
        echo "❌ $(basename "$csv_file")"
        head -n 1 "$csv_file"
        tail -n +2 "$csv_file" | grep -v "^#"
    done
    echo ""
}

# メインループ
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) create_new_request ;;
        2) list_requests ;;
        3) list_approved ;;
        4) list_rejected ;;
        5) 
            if [ -f "$TEMPLATE" ]; then
                cat "$TEMPLATE"
                echo ""
            else
                echo "テンプレートが見つかりません"
            fi
            ;;
        0) 
            echo "終了します"
            break
            ;;
        *)
            echo "無効な選択です"
            ;;
    esac
    
    echo ""
    echo -n "Enterキーで続行..."
    read
    clear
done
