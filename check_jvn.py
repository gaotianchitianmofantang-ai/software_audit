#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
JVNDBで脆弱性情報を確認するスクリプト
"""

import requests
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta
import sys

class JVNChecker:
    def __init__(self):
        self.api_url = "https://jvndb.jvn.jp/myjvn"
        self.namespace = {
            'status': 'http://jvndb.jvn.jp/myjvn/Status',
            'item': 'http://jvndb.jvn.jp/rss/feed/',
        }
    
    def check_vulnerabilities(self, software_name, years=5):
        end_date = datetime.now()
        start_date = end_date - timedelta(days=365*years)
        
        params = {
            'method': 'getVulnOverviewList',
            'keyword': software_name,
            'rangeDatePublished': f'{start_date.strftime("%Y")}-{end_date.strftime("%Y")}',
            'rangeDateFirstPublished': f'{start_date.strftime("%Y")}-{end_date.strftime("%Y")}',
        }
        
        try:
            print(f"[INFO] JVNDBに問い合わせ中: {software_name}")
            response = requests.get(self.api_url, params=params, timeout=30)
            response.raise_for_status()
            
            root = ET.fromstring(response.content)
            status = self._check_status(root)
            if not status['success']:
                return status
            
            vulnerabilities = self._extract_vulnerabilities(root)
            
            result = {
                'success': True,
                'software_name': software_name,
                'check_period': f'{start_date.strftime("%Y-%m-%d")} ～ {end_date.strftime("%Y-%m-%d")}',
                'vulnerability_count': len(vulnerabilities),
                'vulnerabilities': vulnerabilities,
                'passed': len(vulnerabilities) == 0,
            }
            
            return result
            
        except requests.exceptions.RequestException as e:
            return {
                'success': False,
                'error': f'API接続エラー: {str(e)}'
            }
        except ET.ParseError as e:
            return {
                'success': False,
                'error': f'XML解析エラー: {str(e)}'
            }
    
    def _check_status(self, root):
        status_elem = root.find('.//status:statusVersion', self.namespace)
        if status_elem is None:
            for elem in root.iter():
                if 'errMsg' in elem.tag:
                    return {
                        'success': False,
                        'error': f'APIエラー: {elem.text}'
                    }
        return {'success': True}
    
    def _extract_vulnerabilities(self, root):
        vulnerabilities = []
        items = root.findall('.//item') + root.findall('.//{http://jvndb.jvn.jp/rss/feed/}item')
        
        for item in items:
            vuln = {}
            title = item.find('title')
            if title is not None:
                vuln['title'] = title.text
            
            pub_date = item.find('pubDate')
            if pub_date is not None:
                vuln['published_date'] = pub_date.text
            
            link = item.find('link')
            if link is not None:
                vuln['link'] = link.text
            
            description = item.find('description')
            if description is not None:
                vuln['description'] = description.text
            
            vulnerabilities.append(vuln)
        
        return vulnerabilities
    
    def print_report(self, result):
        print("\n" + "="*70)
        print("JVNDBチェック結果")
        print("="*70)
        
        if not result['success']:
            print(f"❌ エラー: {result['error']}")
            return
        
        print(f"対象ソフトウェア: {result['software_name']}")
        print(f"確認期間: {result['check_period']}")
        print(f"検出された脆弱性: {result['vulnerability_count']}件")
        print(f"判定: {'✅ 合格(脆弱性なし)' if result['passed'] else '❌ 不合格(脆弱性あり)'}")
        
        if result['vulnerability_count'] > 0:
            print("\n【検出された脆弱性の詳細】")
            for i, vuln in enumerate(result['vulnerabilities'], 1):
                print(f"\n--- 脆弱性 #{i} ---")
                print(f"タイトル: {vuln.get('title', 'N/A')}")
                print(f"公開日: {vuln.get('published_date', 'N/A')}")
                print(f"リンク: {vuln.get('link', 'N/A')}")
                if vuln.get('description'):
                    desc = vuln['description'][:200] + "..." if len(vuln['description']) > 200 else vuln['description']
                    print(f"説明: {desc}")
        
        print("="*70 + "\n")


def main():
    if len(sys.argv) < 2:
        print("使用方法: python3 check_jvn.py <ソフトウェア名>")
        print("例: python3 check_jvn.py Apache")
        sys.exit(1)
    
    software_name = sys.argv[1]
    checker = JVNChecker()
    result = checker.check_vulnerabilities(software_name)
    checker.print_report(result)
    sys.exit(0 if result.get('passed', False) else 1)


if __name__ == '__main__':
    main()
