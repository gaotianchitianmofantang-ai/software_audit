#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import csv
import os
from datetime import datetime

def process_garoon_csv(csv_path):
    """Garoon CSVファイルを処理"""
    
    print(f"CSVファイルを読み込み中: {csv_path}\n")
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
            
        if len(rows) == 0:
            print("警告: CSVファイルが空です")
            return
        
        # ヘッダー情報（1行目）を解析
        header = rows[0]
        
        print("=" * 60)
        print("例外ソフトウェア利用許可申請書 - 監査レポート")
        print("=" * 60)
        print()
        
        # データ行を処理
        for row in rows:
            if len(row) < 10:
                continue
                
            申請番号 = row[0] if len(row) > 0 else ""
            申請者名 = row[1] if len(row) > 1 else ""
            申請者ID = row[2] if len(row) > 2 else ""
            申請日時 = row[3] if len(row) > 3 else ""
            申請タイトル = row[4] if len(row) > 4 else ""
            ステータス = row[5] if len(row) > 5 else ""
            所属 = row[7] if len(row) > 7 else ""
            ソフトウェア名 = row[9] if len(row) > 9 else ""
            機能 = row[10] if len(row) > 10 else ""
            URL = row[11] if len(row) > 11 else ""
            有償無償 = row[12] if len(row) > 12 else ""
            利用目的 = row[16] if len(row) > 16 else ""
            利用終了日 = row[18] if len(row) > 18 else ""
            
            print(f"【申請番号】 {申請番号}")
            print(f"【申請者】   {申請者名} ({申請者ID})")
            print(f"【所属】     {所属}")
            print(f"【申請日時】 {申請日時}")
            print(f"【ステータス】 {ステータス}")
            print()
            print(f"【ソフトウェア名】 {ソフトウェア名}")
            print(f"【機能】     {機能}")
            print(f"【URL】      {URL}")
            print(f"【ライセンス】 {有償無償}")
            print(f"【利用終了日】 {利用終了日}")
            print()
            print(f"【利用目的】")
            print(f"{利用目的}")
            print()
            print("=" * 60)
            print()
            
            # 監査チェックポイント
            print("【監査チェックポイント】")
            
            issues = []
            
            # チェック1: 利用目的の妥当性
            if not 利用目的 or len(利用目的.strip()) < 20:
                issues.append("⚠ 利用目的が不十分です")
            
            # チェック2: URLの妥当性
            if not URL or URL.strip() == "":
                issues.append("⚠ ソフトウェアのURLが未記入です")
            
            # チェック3: 無償ソフトの場合
            if "無償" in 有償無償:
                issues.append("ℹ 無償ソフトウェアです - 提供元の信頼性確認が必要")
            
            # チェック4: 利用終了日
            if 利用終了日 and "--/--/--" not in 利用終了日:
                issues.append(f"ℹ 期間限定利用 (終了日: {利用終了日})")
            
            if issues:
                for issue in issues:
                    print(f"  {issue}")
            else:
                print("  ✓ 問題なし")
            
            print()
            print("=" * 60)
            print()
        
        # サマリー
        print("\n【監査サマリー】")
        print(f"総申請件数: {len([r for r in rows if len(r) > 10])}件")
        print(f"処理日時: {datetime.now().strftime('%Y/%m/%d %H:%M:%S')}")
        
    except Exception as e:
        print(f"エラー: CSVファイルの処理中に問題が発生しました")
        print(f"詳細: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("使用方法: python3 process_garoon_csv.py <CSVファイルパス>")
        sys.exit(1)
    
    csv_path = sys.argv[1]
    
    if not os.path.exists(csv_path):
        print(f"エラー: ファイルが見つかりません: {csv_path}")
        sys.exit(1)
    
    process_garoon_csv(csv_path)
