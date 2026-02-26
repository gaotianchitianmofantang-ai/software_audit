#!/usr/bin/env python3
"""
ワークフロー申請ソフトウェア審査システム
"""

import csv
import os
import sys
from datetime import datetime
from pathlib import Path
import json
from typing import Dict, List, Tuple
import shutil

class WorkflowAuditor:
    """ワークフロー申請の審査を行うクラス"""
    
    def __init__(self, config_path: str = "config/audit_rules.json"):
        """
        初期化
        
        Args:
            config_path: 審査ルール設定ファイルのパス
        """
        self.pending_dir = Path("data/pending")
        self.approved_dir = Path("data/approved")
        self.rejected_dir = Path("data/rejected")
        self.archive_dir = Path("data/archive")
        self.reports_dir = Path("reports")
        
        # ディレクトリ作成
        for dir_path in [self.pending_dir, self.approved_dir, 
                         self.rejected_dir, self.archive_dir, self.reports_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
        
        # 審査ルールの読み込み
        self.config_path = Path(config_path)
        self.rules = self._load_rules()
    
    def _load_rules(self) -> Dict:
        """審査ルールを読み込む"""
        if self.config_path.exists():
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        else:
            # デフォルトルール
            default_rules = {
                "auto_approve": {
                    "free_software": True,
                    "known_vendors": [
                        "Microsoft", "Google", "Apple", "Mozilla",
                        "Python Software Foundation", "Linux Foundation"
                    ],
                    "max_cost_yen": 10000
                },
                "auto_reject": {
                    "prohibited_categories": ["P2P", "暗号通貨マイニング"],
                    "high_risk_licenses": ["不明", "独自"]
                },
                "require_manual_review": {
                    "high_cost_threshold": 50000,
                    "sensitive_departments": ["経理部", "人事部"],
                    "security_keywords": ["リモートアクセス", "VPN", "暗号化"]
                }
            }
            
            # 設定ファイルを保存
            self.config_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(default_rules, f, ensure_ascii=False, indent=2)
            
            return default_rules
    
    def load_csv(self, csv_path: Path) -> List[Dict]:
        """CSVファイルを読み込む"""
        applications = []
        
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                applications.append(row)
        
        return applications
    
    def audit_application(self, app: Dict) -> Tuple[str, str, List[str]]:
        """
        個別の申請を審査
        
        Returns:
            (判定, 理由, フラグリスト)
            判定: 'approved', 'rejected', 'manual_review'
        """
        flags = []
        reasons = []
        
        # コスト抽出
        try:
            cost_str = app.get('コスト', '0円').replace('円', '').replace(',', '').replace('/', '年').split()[0]
            cost = int(cost_str) if cost_str.isdigit() else 0
        except:
            cost = 0
            flags.append('コスト不明')
        
        # 1. 自動承認チェック
        vendor = app.get('ベンダー', '')
        license_type = app.get('ライセンス形態', '')
        
        if cost == 0 and '無料' in license_type:
            if vendor in self.rules['auto_approve']['known_vendors']:
                return 'approved', '信頼できるベンダーの無料ソフトウェア', flags
        
        if cost <= self.rules['auto_approve']['max_cost_yen']:
            reasons.append(f'低コスト({cost}円)')
            flags.append('自動承認候補')
        
        # 2. 自動却下チェック
        purpose = app.get('利用目的', '')
        for prohibited in self.rules['auto_reject']['prohibited_categories']:
            if prohibited in purpose or prohibited in app.get('ソフトウェア名', ''):
                return 'rejected', f'禁止カテゴリ: {prohibited}', flags
        
        if license_type in self.rules['auto_reject']['high_risk_licenses']:
            return 'rejected', f'高リスクライセンス: {license_type}', flags
        
        # 3. 手動レビュー必要チェック
        department = app.get('部署', '')
        
        if cost > self.rules['require_manual_review']['high_cost_threshold']:
            reasons.append(f'高額({cost}円)')
            return 'manual_review', '高額のため手動審査が必要', reasons
        
        if department in self.rules['require_manual_review']['sensitive_departments']:
            reasons.append(f'機密部署: {department}')
            return 'manual_review', '機密部署のため手動審査が必要', reasons
        
        for keyword in self.rules['require_manual_review']['security_keywords']:
            if keyword in purpose or keyword in app.get('備考', ''):
                reasons.append(f'セキュリティキーワード: {keyword}')
                return 'manual_review', 'セキュリティ要件のため手動審査が必要', reasons
        
        # デフォルトは承認
        return 'approved', '基準を満たしている', flags
    
    def process_csv(self, csv_path: Path) -> Dict:
        """CSVファイル全体を処理"""
        applications = self.load_csv(csv_path)
        
        results = {
            'approved': [],
            'rejected': [],
            'manual_review': []
        }
        
        for app in applications:
            decision, reason, flags = self.audit_application(app)
            
            app['審査結果'] = decision
            app['審査理由'] = reason
            app['フラグ'] = ', '.join(flags) if flags else 'なし'
            app['審査日時'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            results[decision].append(app)
        
        return results
    
    def save_results(self, results: Dict, original_filename: str):
        """審査結果を保存"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        base_name = Path(original_filename).stem
        
        for decision, apps in results.items():
            if not apps:
                continue
            
            output_dir = getattr(self, f'{decision}_dir')
            output_path = output_dir / f'{base_name}_{decision}_{timestamp}.csv'
            
            # CSV出力
            if apps:
                fieldnames = list(apps[0].keys())
                with open(output_path, 'w', encoding='utf-8', newline='') as f:
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(apps)
                
                print(f"✅ {decision}: {len(apps)}件 → {output_path}")
    
    def generate_report(self, results: Dict, original_filename: str) -> str:
        """審査レポートを生成"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        base_name = Path(original_filename).stem
        report_path = self.reports_dir / f'audit_report_{base_name}_{timestamp}.html'
        
        total = sum(len(apps) for apps in results.values())
        
        html = f"""<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>ソフトウェア申請審査レポート</title>
    <style>
        body {{ font-family: 'Segoe UI', Meiryo, sans-serif; margin: 20px; }}
        h1 {{ color: #2c3e50; }}
        .summary {{ background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 20px 0; }}
        .summary-item {{ display: inline-block; margin: 10px 20px; }}
        .approved {{ color: #27ae60; font-weight: bold; }}
        .rejected {{ color: #e74c3c; font-weight: bold; }}
        .manual {{ color: #f39c12; font-weight: bold; }}
        table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        th {{ background: #34495e; color: white; }}
        tr:nth-child(even) {{ background: #f2f2f2; }}
        .section {{ margin: 30px 0; }}
    </style>
</head>
<body>
    <h1>📋 ソフトウェア申請審査レポート</h1>
    <p>審査日時: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}</p>
    <p>対象ファイル: {original_filename}</p>
    
    <div class="summary">
        <h2>概要</h2>
        <div class="summary-item">総申請数: <strong>{total}</strong></div>
        <div class="summary-item approved">承認: {len(results['approved'])}</div>
        <div class="summary-item rejected">却下: {len(results['rejected'])}</div>
        <div class="summary-item manual">要手動審査: {len(results['manual_review'])}</div>
    </div>
"""
        
        for decision in ['approved', 'rejected', 'manual_review']:
            apps = results[decision]
            if not apps:
                continue
            
            decision_label = {
                'approved': '✅ 承認',
                'rejected': '❌ 却下',
                'manual_review': '⚠️ 要手動審査'
            }[decision]
            
            html += f"""
    <div class="section">
        <h2>{decision_label} ({len(apps)}件)</h2>
        <table>
            <tr>
                <th>申請ID</th>
                <th>申請者</th>
                <th>部署</th>
                <th>ソフトウェア名</th>
                <th>ベンダー</th>
                <th>コスト</th>
                <th>審査理由</th>
            </tr>
"""
            
            for app in apps:
                html += f"""
            <tr>
                <td>{app.get('申請ID', '')}</td>
                <td>{app.get('申請者', '')}</td>
                <td>{app.get('部署', '')}</td>
                <td>{app.get('ソフトウェア名', '')}</td>
                <td>{app.get('ベンダー', '')}</td>
                <td>{app.get('コスト', '')}</td>
                <td>{app.get('審査理由', '')}</td>
            </tr>
"""
            
            html += """
        </table>
    </div>
"""
        
        html += """
</body>
</html>
"""
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(html)
        
        print(f"\n📊 レポート生成: {report_path}")
        return str(report_path)


def main():
    """メイン処理"""
    auditor = WorkflowAuditor()
    
    # pendingディレクトリ内のCSVファイルを処理
    csv_files = list(auditor.pending_dir.glob('*.csv'))
    
    if not csv_files:
        print("❌ data/pending/ にCSVファイルがありません")
        print("\n使用方法:")
        print("  1. ワークフローシステムからCSVをエクスポート")
        print("  2. data/pending/ に配置")
        print("  3. このスクリプトを実行")
        return 1
    
    print(f"🔍 {len(csv_files)}個のCSVファイルを検出\n")
    
    for csv_file in csv_files:
        if csv_file.name == 'sample.csv':
            print(f"⏭️  スキップ: {csv_file.name} (サンプルファイル)")
            continue
        
        print(f"\n{'='*60}")
        print(f"📂 処理中: {csv_file.name}")
        print(f"{'='*60}")
        
        try:
            # 審査実行
            results = auditor.process_csv(csv_file)
            
            # 結果保存
            auditor.save_results(results, csv_file.name)
            
            # レポート生成
            report_path = auditor.generate_report(results, csv_file.name)
            
            # 処理済みファイルをアーカイブ
            archive_path = auditor.archive_dir / f"{csv_file.stem}_processed_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            shutil.move(str(csv_file), str(archive_path))
            print(f"📦 アーカイブ: {archive_path}")
            
        except Exception as e:
            print(f"❌ エラー: {csv_file.name} - {str(e)}")
            continue
    
    print(f"\n{'='*60}")
    print("✅ すべての処理が完了しました")
    print(f"{'='*60}")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
