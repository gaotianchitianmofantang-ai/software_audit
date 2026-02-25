#!/usr/bin/env python3
"""
ソフトウェア監査システム ダッシュボード
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path

class SoftwareAuditDashboard:
    def __init__(self):
        self.base_dir = Path(".")
        self.reports_dir = self.base_dir / "audit_reports"
        self.exceptions_dir = self.base_dir / "exceptions"
        self.requests_dir = self.exceptions_dir / "requests"
        self.approved_dir = self.exceptions_dir / "approved"
        self.reports_exception_dir = self.exceptions_dir / "reports"
        self.archive_dir = self.exceptions_dir / "archive"
        self.whitelist_dir = self.base_dir / "whitelist"
        
        # ディレクトリ作成
        for d in [self.reports_dir, self.requests_dir, self.approved_dir, 
                  self.reports_exception_dir, self.archive_dir, self.whitelist_dir]:
            d.mkdir(parents=True, exist_ok=True)
    
    def count_files(self, directory):
        """ディレクトリ内のファイル数をカウント"""
        try:
            return len(list(directory.glob("*")))
        except:
            return 0
    
    def get_recent_files(self, directory, limit=5):
        """最近のファイルを取得"""
        try:
            files = sorted(directory.glob("*"), key=lambda x: x.stat().st_mtime, reverse=True)
            return files[:limit]
        except:
            return []
    
    def display_dashboard(self):
        """ダッシュボードを表示"""
        os.system('clear' if os.name == 'posix' else 'cls')
        
        print("╔" + "="*64 + "╗")
        print("║" + " "*64 + "║")
        print("║" + " "*10 + "ソフトウェア監査システム ダッシュボード" + " "*11 + "║")
        print("║" + " "*64 + "║")
        print("╚" + "="*64 + "╝")
        print()
        
        # 統計情報
        print("📊 システム統計")
        print("━" * 80)
        print(f"申請中:              {self.count_files(self.requests_dir):5} 件")
        print(f"承認済み:            {self.count_files(self.approved_dir):5} 件")
        print(f"例外レポート:        {self.count_files(self.reports_exception_dir):5} 件")
        print(f"アーカイブ:          {self.count_files(self.archive_dir):5} 件")
        print(f"全監査レポート:      {self.count_files(self.reports_dir):5} 件")
        print(f"ホワイトリスト登録:  {self.count_files(self.whitelist_dir):5} 件")
        print()
        
        # 最近の承認
        print("📋 最近の承認 (最新5件)")
        print("━" * 80)
        approved_files = self.get_recent_files(self.approved_dir, 5)
        if approved_files:
            for i, f in enumerate(approved_files, 1):
                mtime = datetime.fromtimestamp(f.stat().st_mtime)
                print(f"[{i}] {f.name}")
                print(f"    承認日時: {mtime.strftime('%Y-%m-%d %H:%M:%S')}")
                print()
        else:
            print("  承認済み申請はありません")
            print()
        
        # ホワイトリスト
        print("✅ ホワイトリスト登録ソフトウェア")
        print("━" * 80)
        whitelist_files = self.get_recent_files(self.whitelist_dir, 10)
        if whitelist_files:
            for f in whitelist_files:
                mtime = datetime.fromtimestamp(f.stat().st_mtime)
                print(f"  ✓ {f.stem} - 登録日: {mtime.strftime('%Y-%m-%d')}")
        else:
            print("  ホワイトリストは空です")
        print()
    
    def show_menu(self):
        """メニューを表示"""
        print("╔" + "="*64 + "╗")
        print("║" + " "*24 + "メニュー" + " "*31 + "║")
        print("╚" + "="*64 + "╝")
        print()
        print("  [1] 新規申請を作成")
        print("  [2] 申請を審査（対話式）")
        print("  [3] 結果を表示")
        print("  [4] レポートを表示")
        print("  [5] 監査ログを確認")
        print("  [6] システム情報")
        print("  [9] ダッシュボード更新")
        print("  [0] 終了")
        print()
    
    def show_reports_menu(self):
        """レポート表示メニュー"""
        while True:
            os.system('clear' if os.name == 'posix' else 'cls')
            print("=" * 60)
            print("  レポート表示")
            print("=" * 60)
            print()
            print("  [1] 全監査レポート")
            print("  [2] 例外申請レポート")
            print("  [3] 承認済み申請")
            print("  [4] ホワイトリスト")
            print("  [0] 戻る")
            print()
            
            choice = input("選択してください: ").strip()
            
            if choice == "1":
                self.list_reports(self.reports_dir, "全監査レポート")
            elif choice == "2":
                self.list_reports(self.reports_exception_dir, "例外申請レポート")
            elif choice == "3":
                self.list_reports(self.approved_dir, "承認済み申請")
            elif choice == "4":
                self.list_reports(self.whitelist_dir, "ホワイトリスト")
            elif choice == "0":
                break
    
    def list_reports(self, directory, title):
        """レポート一覧を表示"""
        os.system('clear' if os.name == 'posix' else 'cls')
        print("=" * 60)
        print(f"  {title}")
        print("=" * 60)
        print()
        
        files = sorted(directory.glob("*"), key=lambda x: x.stat().st_mtime, reverse=True)
        
        if not files:
            print("  レポートはありません")
            input("\nEnterキーで戻る...")
            return
        
        for i, f in enumerate(files, 1):
            mtime = datetime.fromtimestamp(f.stat().st_mtime)
            size = f.stat().st_size
            print(f"[{i:2}] {f.name}")
            print(f"     更新: {mtime.strftime('%Y-%m-%d %H:%M:%S')} | サイズ: {size:,} bytes")
        
        print()
        choice = input("表示するレポート番号 (0で戻る): ").strip()
        
        try:
            idx = int(choice)
            if 1 <= idx <= len(files):
                self.show_file_content(files[idx - 1])
        except:
            pass
    
    def show_file_content(self, filepath):
        """ファイル内容を表示"""
        os.system('clear' if os.name == 'posix' else 'cls')
        print("=" * 60)
        print(f"  {filepath.name}")
        print("=" * 60)
        print()
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                print(content)
        except Exception as e:
            print(f"エラー: {e}")
        
        print()
        input("\nEnterキーで戻る...")
    
    def show_audit_logs(self):
        """監査ログを表示"""
        os.system('clear' if os.name == 'posix' else 'cls')
        print("=" * 60)
        print("  監査ログ")
        print("=" * 60)
        print()
        
        # すべてのレポートディレクトリから最新10件を取得
        all_files = []
        for d in [self.reports_dir, self.reports_exception_dir, self.approved_dir]:
            all_files.extend(d.glob("*"))
        
        recent = sorted(all_files, key=lambda x: x.stat().st_mtime, reverse=True)[:10]
        
        if not recent:
            print("  ログはありません")
        else:
            for i, f in enumerate(recent, 1):
                mtime = datetime.fromtimestamp(f.stat().st_mtime)
                print(f"[{i}] {mtime.strftime('%Y-%m-%d %H:%M:%S')} - {f.parent.name}/{f.name}")
        
        print()
        input("\nEnterキーで戻る...")
    
    def show_system_info(self):
        """システム情報を表示"""
        os.system('clear' if os.name == 'posix' else 'cls')
        print("=" * 60)
        print("  システム情報")
        print("=" * 60)
        print()
        
        print(f"作業ディレクトリ: {self.base_dir.absolute()}")
        print(f"監査レポート:     {self.reports_dir}")
        print(f"例外申請:         {self.exceptions_dir}")
        print(f"ホワイトリスト:   {self.whitelist_dir}")
        print()
        
        print("ディレクトリサイズ:")
        for name, d in [
            ("監査レポート", self.reports_dir),
            ("例外レポート", self.reports_exception_dir),
            ("承認済み", self.approved_dir),
            ("アーカイブ", self.archive_dir)
        ]:
            size = sum(f.stat().st_size for f in d.glob("*") if f.is_file())
            print(f"  {name:20}: {size:10,} bytes")
        
        print()
        input("\nEnterキーで戻る...")
    
    def run(self):
        """メインループ"""
        while True:
            self.display_dashboard()
            self.show_menu()
            
            choice = input("選択してください: ").strip()
            
            if choice == "1":
                print("\n新規申請は以下のコマンドで実行してください:")
                print("./software_audit.sh <ソフトウェア名> <URL> --purpose \"利用目的\"")
                input("\nEnterキーで続行...")
            elif choice == "2":
                print("\n申請審査は以下のコマンドで実行してください:")
                print("./audit_exceptions.sh")
                input("\nEnterキーで続行...")
            elif choice == "3":
                self.show_audit_logs()
            elif choice == "4":
                self.show_reports_menu()
            elif choice == "5":
                self.show_audit_logs()
            elif choice == "6":
                self.show_system_info()
            elif choice == "9":
                continue  # ダッシュボード更新
            elif choice == "0":
                print("\n終了します")
                break
            else:
                print("\n無効な選択です")
                input("\nEnterキーで続行...")

def main():
    dashboard = SoftwareAuditDashboard()
    dashboard.run()

if __name__ == "__main__":
    main()
