#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ソフトウェアセキュリティ自動審査システム
"""

import sys
import json
import os
import csv
import requests
from datetime import datetime
from io import StringIO

# ============================================
# 設定
# ============================================
SERPAPI_KEY = os.environ.get('SERPAPI_KEY', '')  # 環境変数から取得

# ============================================
# CSV解析
# ============================================
def parse_csv(csv_path):
    """CSVファイルから申請情報を抽出"""
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        csv_reader = csv.reader(StringIO(content))
        rows = list(csv_reader)
        
        if len(rows) == 0:
            return None
        
        data = rows[0]
        
        def get_value(index, default=""):
            return data[index].strip() if index < len(data) else default
        
        return {
            "申請番号": get_value(0),
            "申請者": get_value(1),
            "申請日時": get_value(3),
            "ステータス": get_value(5),
            "所属": get_value(7),
            "ソフトウェア名": get_value(9),
            "主な機能": get_value(10),
            "参考URL": get_value(11),
            "有償無償": get_value(12),
            "利用目的": get_value(17)
        }
    except Exception as e:
        print(f"エラー: CSV解析失敗 - {e}", file=sys.stderr)
        return None

# ============================================
# Web検索（SerpAPI使用）
# ============================================
def search_web(query, num_results=5):
    """Web検索を実行"""
    if not SERPAPI_KEY:
        return {
            "status": "no_api_key",
            "message": "SERPAPI_KEYが設定されていません",
            "results": []
        }
    
    try:
        url = "https://serpapi.com/search"
        params = {
            "q": query,
            "api_key": SERPAPI_KEY,
            "num": num_results,
            "hl": "ja",
            "gl": "jp"
        }
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        results = []
        for item in data.get("organic_results", [])[:num_results]:
            results.append({
                "title": item.get("title", ""),
                "url": item.get("link", ""),
                "snippet": item.get("snippet", "")
            })
        
        return {
            "status": "success",
            "query": query,
            "results": results
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
            "results": []
        }

# ============================================
# JVN iPedia検索（脆弱性データベース）
# ============================================
def search_jvn(software_name):
    """JVN iPediaで脆弱性情報を検索"""
    try:
        # JVN iPediaのAPI（MyJVN）を使用
        url = "https://jvndb.jvn.jp/myjvn"
        params = {
            "method": "getVulnOverviewList",
            "keyword": software_name,
            "rangeDatePublished": "n",
            "rangeDateFirstPublished": "n",
            "datePublicStartY": datetime.now().year - 5,  # 過去5年
            "feed": "hnd"
        }
        
        response = requests.get(url, params=params, timeout=10)
        
        # 簡易的な件数カウント（実際はXMLパース必要）
        vuln_count = response.text.count("<item>")
        
        return {
            "status": "success",
            "vulnerability_count": vuln_count,
            "search_url": f"https://jvndb.jvn.jp/search/index.php?mode=_vulnerability_search_IA_VulnSearch&keyword={software_name}",
            "message": f"過去5年間で{vuln_count}件の脆弱性報告"
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
            "vulnerability_count": "不明"
        }

# ============================================
# 自動審査ロジック
# ============================================
def conduct_audit(info):
    """自動審査を実施"""
    software_name = info.get("ソフトウェア名", "")
    is_paid = info.get("有償無償", "")
    
    audit_result = {
        "審査日時": datetime.now().isoformat(),
        "ソフトウェア名": software_name,
        "審査項目": []
    }
    
    # ----------------------------------------
    # 審査1: セキュリティ事故報告の確認
    # ----------------------------------------
    print(f"[審査1] セキュリティ事故報告を確認中...")
    incident_search = search_web(f"{software_name} セキュリティ インシデント 情報漏洩", num_results=3)
    
    # 判定ロジック（簡易版）
    incident_keywords = ["情報漏洩", "セキュリティ侵害", "脆弱性", "ハッキング", "不正アクセス"]
    incident_found = False
    
    for result in incident_search.get("results", []):
        snippet = result.get("snippet", "").lower()
        if any(keyword in snippet for keyword in incident_keywords):
            incident_found = True
            break
    
    audit_item_1 = {
        "項目名": "セキュリティ事故報告の確認",
        "判定": "要注意" if incident_found else "問題なし",
        "理由": "過去にセキュリティ関連の報道あり" if incident_found else "重大なセキュリティ事故の報告なし",
        "根拠": incident_search.get("results", [])[:2],
        "検索クエリ": incident_search.get("query", "")
    }
    audit_result["審査項目"].append(audit_item_1)
    
    # ----------------------------------------
    # 審査2: 脆弱性データベース確認
    # ----------------------------------------
    print(f"[審査2] 脆弱性情報を確認中...")
    jvn_result = search_jvn(software_name)
    
    vuln_count = jvn_result.get("vulnerability_count", 0)
    
    if "有償" in is_paid:
        # 有償ソフト: 5年で10件以上は要注意
        vuln_judgement = "要注意" if vuln_count >= 10 else "問題なし"
        vuln_reason = f"過去5年間で{vuln_count}件の脆弱性報告（10件以上は要注意）"
    else:
        # 無償ソフト: 5年で5件以上は要注意
        vuln_judgement = "要注意" if vuln_count >= 5 else "問題なし"
        vuln_reason = f"過去5年間で{vuln_count}件の脆弱性報告（5件以上は要注意）"
    
    audit_item_2 = {
        "項目名": "脆弱性データベース確認（JVN iPedia）",
        "判定": vuln_judgement,
        "理由": vuln_reason,
        "根拠": [{"title": "JVN iPedia検索結果", "url": jvn_result.get("search_url", "")}],
        "詳細": jvn_result
    }
    audit_result["審査項目"].append(audit_item_2)
    
    # ----------------------------------------
    # 審査3: 提供元の評判確認
    # ----------------------------------------
    print(f"[審査3] 提供元の評判を確認中...")
    reputation_search = search_web(f"{software_name} 評判 レビュー", num_results=3)
    
    # 簡易判定
    negative_keywords = ["危険", "注意", "おすすめしない", "問題", "トラブル"]
    negative_found = False
    
    for result in reputation_search.get("results", []):
        snippet = result.get("snippet", "").lower()
        if any(keyword in snippet for keyword in negative_keywords):
            negative_found = True
            break
    
    audit_item_3 = {
        "項目名": "提供元の評判確認",
        "判定": "要注意" if negative_found else "問題なし",
        "理由": "ネガティブな評判が見られる" if negative_found else "特に問題となる評判は見当たらない",
        "根拠": reputation_search.get("results", [])[:2],
        "検索クエリ": reputation_search.get("query", "")
    }
    audit_result["審査項目"].append(audit_item_3)
    
    # ----------------------------------------
    # 総合判定
    # ----------------------------------------
    judgements = [item["判定"] for item in audit_result["審査項目"]]
    
    if "要注意" in judgements:
        final_judgement = "条件付き承認"
        final_reason = "一部の審査項目で要注意事項あり。詳細確認の上、条件付きで承認可能"
    else:
        final_judgement = "承認"
        final_reason = "全ての審査項目で問題なし"
    
    audit_result["総合判定"] = final_judgement
    audit_result["判定理由"] = final_reason
    
    return audit_result

# ============================================
# レポート生成
# ============================================
def generate_report(info, audit_result, output_path):
    """Markdownレポートを生成"""
    software_name = info.get("ソフトウェア名", "")
    
    report = f"""# ソフトウェアセキュリティ審査レポート

**生成日時**: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}  
**審査対象**: {software_name}  
**有償/無償**: {info.get('有償無償', '')}  
**申請番号**: {info.get('申請番号', '')}

---

## 📋 申請情報

"""
    
    for key, value in info.items():
        if value:
            report += f"- **{key}**: {value}\n"
    
    report += f"""

---

## 🔍 自動審査結果

**審査日時**: {audit_result.get('審査日時', '')}

"""
    
    for idx, item in enumerate(audit_result.get("審査項目", []), 1):
        status_icon = "⚠️" if item["判定"] == "要注意" else "✅"
        
        report += f"""### {status_icon} 審査{idx}: {item['項目名']}

**判定**: {item['判定']}  
**理由**: {item['理由']}

**検索根拠**:
"""
        
        for evidence in item.get("根拠", []):
            title = evidence.get("title", "")
            url = evidence.get("url", "")
            snippet = evidence.get("snippet", "")
            report += f"""
- **{title}**  
  URL: {url}  
  概要: {snippet}
"""
        
        report += "\n---\n\n"
    
    # 総合判定
    final_icon = "✅" if audit_result.get("総合判定") == "承認" else "⚠️"
    
    report += f"""## {final_icon} 総合判定

**最終判定**: {audit_result.get('総合判定', '')}  
**判定理由**: {audit_result.get('判定理由', '')}

---

## 📝 審査者記入欄

**最終承認者**: __________________  
**承認日**: __________________  
**特記事項**:  


"""
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)

# ============================================
# メイン処理
# ============================================
def main():
    if len(sys.argv) < 2:
        print("使い方: python3 auto_audit.py [CSVファイルパス]", file=sys.stderr)
        sys.exit(1)
    
    csv_path = sys.argv[1]
    
    # CSV解析
    print("=" * 60)
    print("ソフトウェアセキュリティ自動審査システム")
    print("=" * 60)
    print(f"\n📄 CSVファイル: {csv_path}\n")
    
    info = parse_csv(csv_path)
    if not info:
        print("エラー: CSV解析に失敗しました", file=sys.stderr)
        sys.exit(1)
    
    software_name = info.get("ソフトウェア名", "")
    print(f"🔍 審査対象: {software_name}\n")
    
    # 自動審査実行
    audit_result = conduct_audit(info)
    
    # 結果保存
    script_dir = os.path.dirname(os.path.abspath(__file__))
    reports_dir = os.path.join(script_dir, "reports")
    results_dir = os.path.join(script_dir, "audit_results")
    os.makedirs(reports_dir, exist_ok=True)
    os.makedirs(results_dir, exist_ok=True)
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    basename = os.path.splitext(os.path.basename(csv_path))[0]
    
    # JSON結果保存
    json_path = os.path.join(results_dir, f"審査結果_{basename}_{timestamp}.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump({
            "申請情報": info,
            "審査結果": audit_result
        }, f, ensure_ascii=False, indent=2)
    
    # Markdownレポート生成
    report_path = os.path.join(reports_dir, f"審査レポート_{basename}_{timestamp}.md")
    generate_report(info, audit_result, report_path)
    
    # 結果表示
    print("\n" + "=" * 60)
    print(f"✅ 審査完了: {audit_result.get('総合判定', '')}")
    print("=" * 60)
    print(f"\n📊 審査結果 (JSON): {json_path}")
    print(f"📄 審査レポート (MD): {report_path}\n")

if __name__ == "__main__":
    main()
