#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
審査レポートサマリー生成ツール
audit_reports/ 内のレポートを集計してサマリーを生成
"""

import os
import re
from datetime import datetime
from pathlib import Path

def parse_report(report_path):
    """レポートファイルを解析"""
    with open(report_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # ソフトウェア名
    name_match = re.search(r'対象ソフトウェア:\s*(.+)', content)
    software_name = name_match.group(1) if name_match else 'Unknown'
    
    # 審査日時
    date_match = re.search(r'審査実施日時:\s*(.+)', content)
    audit_date = date_match.group(1) if date_match else 'Unknown'
    
    # 総合判定
    result_match = re.search(r'総合判定:\s*(.+)', content)
    result = result_match.group(1).strip() if result_match else 'Unknown'
    
    # 脆弱性数
    vuln_match = re.search(r'検出された脆弱性:\s*(\d+)件', content)
    vuln_count = int(vuln_match.group(1)) if vuln_match else None
    
    # コミット数
    commit_match = re.search(r'コミット数（12ヶ月）:\s*(\d+)件', content)
    commit_count = int(commit_match.group(1)) if commit_match else None
    
    return {
        'software_name': software_name,
        'audit_date': audit_date,
        'result': result,
        'vuln_count': vuln_count,
        'commit_count': commit_count,
        'file_path': report_path
    }

def generate_summary():
    """サマリーを生成"""
    reports_dir = Path('audit_reports')
    
    if not reports_dir.exists():
        print("❌ audit_reports/ ディレクトリが見つかりません")
        return
    
    report_files = sorted(reports_dir.glob('audit_*.txt'), reverse=True)
    
    if not report_files:
        print("❌ レポートファイルが見つかりません")
        return
    
    print("=" * 80)
    print("ソフトウェア審査サマリーレポート")
    print("=" * 80)
    print(f"生成日時: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}")
    print(f"レポート総数: {len(report_files)}件")
    print("=" * 80)
    print()
    
    # 統計
    total = len(report_files)
    passed = 0
    failed = 0
    total_vulns = 0
    
    # ソフトウェアごとの最新レポートを取得
    software_reports = {}
    
    for report_file in report_files:
        data = parse_report(report_file)
        sw_name = data['software_name']
        
        # 最新のレポートのみを保持
        if sw_name not in software_reports:
            software_reports[sw_name] = data
            
            if '✅ 合格' in data['result']:
                passed += 1
            else:
                failed += 1
            
            if data['vuln_count'] is not None:
                total_vulns += data['vuln_count']
    
    # サマリー表示
    print("■ 統計情報")
    print("-" * 80)
    print(f"審査対象ソフトウェア数: {len(software_reports)}件")
    print(f"合格: {passed}件 ✅")
    print(f"不合格: {failed}件 ❌")
    print(f"検出された脆弱性総数: {total_vulns}件")
    print()
    
    # 詳細リスト
    print("■ ソフトウェア別結果")
    print("-" * 80)
    print(f"{'No.':<4} {'ソフトウェア名':<30} {'判定':<10} {'脆弱性':<8} {'審査日'}")
    print("-" * 80)
    
    for i, (sw_name, data) in enumerate(sorted(software_reports.items()), 1):
        result_symbol = '✅' if '✅ 合格' in data['result'] else '❌'
        vuln_str = f"{data['vuln_count']}件" if data['vuln_count'] is not None else 'N/A'
        audit_date_short = data['audit_date'].split()[0] if data['audit_date'] != 'Unknown' else 'N/A'
        
        print(f"{i:<4} {sw_name:<30} {result_symbol:<10} {vuln_str:<8} {audit_date_short}")
    
    print("=" * 80)

if __name__ == '__main__':
    generate_summary()
