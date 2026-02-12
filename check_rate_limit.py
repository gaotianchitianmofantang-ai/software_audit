#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
GitHub APIレート制限チェッカー
現在のGitHub APIレート制限の状況を確認します
"""

import os
import sys
from datetime import datetime
from github import Github, Auth

def check_rate_limit():
    """
    GitHub APIのレート制限を確認
    """
    github_token = os.environ.get('GITHUB_TOKEN')
    
    if github_token:
        auth = Auth.Token(github_token)
        g = Github(auth=auth)
        auth_status = "✅ 認証済み（Token使用中）"
        token_display = f"{github_token[:10]}...{github_token[-4:]}"
    else:
        g = Github()
        auth_status = "⚠️  未認証（匿名アクセス）"
        token_display = "なし"
    
    try:
        rate_limit = g.get_rate_limit()
        
        # PyGithub 2.8.1では rate_limit.resources.core でアクセス
        core = rate_limit.resources.core
        limit = core.limit
        remaining = core.remaining
        reset_timestamp = core.reset.timestamp()
        reset_time = datetime.fromtimestamp(reset_timestamp)
        
        # 現在時刻
        now = datetime.now()
        
        # 使用率計算
        used = limit - remaining
        usage_percent = (used / limit) * 100 if limit > 0 else 0
        
        # 結果表示
        print("=" * 70)
        print("GitHub APIレート制限の状況")
        print("=" * 70)
        print(f"認証状態: {auth_status}")
        if github_token:
            print(f"使用中のToken: {token_display}")
        print(f"リクエスト上限: {limit:,} 回/時")
        print(f"残りリクエスト数: {remaining:,} 回")
        print(f"現在時刻: {now.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"リセット時刻: {reset_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        print(f"使用状況: {used}/{limit:,} ({usage_percent:.1f}%)")
        
        # 判定
        if remaining > 1000:
            print("✅ 十分なリクエスト数が残っています")
        elif remaining > 100:
            print("⚠️  残りリクエスト数が少なくなっています")
        else:
            print("❌ リクエスト数がほぼ上限に達しています")
            print(f"   リセットまで待つか、新しいTokenを使用してください")
        
        print("=" * 70)
        
        # その他のAPIのレート制限も表示
        search = rate_limit.resources.search
        graphql = rate_limit.resources.graphql
        
        print(f"\n[検索API] 上限: {search.limit} 回/時, 残り: {search.remaining} 回")
        print(f"[GraphQL API] 上限: {graphql.limit} 回/時, 残り: {graphql.remaining} 回")
        
        return remaining > 0
        
    except Exception as e:
        print(f"❌ エラー: {type(e).__name__} - {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    success = check_rate_limit()
    sys.exit(0 if success else 1)
