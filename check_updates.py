#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
GitHub更新頻度チェックツール
指定されたGitHubリポジトリの更新頻度をチェックします
"""

import os
import sys
from datetime import datetime, timedelta, timezone
from github import Github, Auth, GithubException

class GitHubUpdateChecker:
    def __init__(self, github_token=None):
        """
        GitHubUpdateCheckerの初期化
        
        Args:
            github_token (str): GitHub Personal Access Token
        """
        self.github_token = github_token or os.environ.get('GITHUB_TOKEN')
        
        if self.github_token:
            auth = Auth.Token(self.github_token)
            self.github = Github(auth=auth)
            print("[INFO] GitHub Token使用中（認証済み）")
            
            # レート制限の確認
            try:
                rate_limit = self.github.get_rate_limit()
                remaining = rate_limit.resources.core.remaining
                print(f"[INFO] GitHub API残りリクエスト数: {remaining}")
            except:
                print("[INFO] レート制限の取得をスキップしました")
        else:
            self.github = Github()
            print("[WARNING] GitHub Tokenが設定されていません（匿名アクセス）")
            print("[WARNING] レート制限: 60回/時")

    def check_github_updates(self, repo_url):
        """
        GitHubリポジトリの更新頻度をチェック
        
        Args:
            repo_url (str): GitHubリポジトリのURL
            
        Returns:
            dict: チェック結果
        """
        try:
            # URLからリポジトリ名を抽出
            repo_path = repo_url.replace('https://github.com/', '').replace('http://github.com/', '').strip('/')
            
            print(f"\n{'='*70}")
            print("更新頻度チェック結果")
            print('='*70)
            print(f"対象リポジトリ: {repo_path}")
            print(f"URL: {repo_url}")
            
            # リポジトリ情報を取得
            repo = self.github.get_repo(repo_path)
            
            # タイムゾーン付きの現在日時（UTC）
            now = datetime.now(timezone.utc)
            threshold_date = now - timedelta(days=365)  # 12ヶ月前
            
            print(f"確認期間: 直近12ヶ月")
            print(f"基準日: {threshold_date.strftime('%Y-%m-%d')}")
            
            # リポジトリの基本情報
            print(f"最終更新日: {repo.updated_at}")
            
            # 最新のコミット情報を取得
            commits = repo.get_commits(since=threshold_date)
            commit_count = commits.totalCount
            
            print(f"最終コミット日: {commits[0].commit.author.date if commit_count > 0 else 'N/A'}")
            print(f"コミット数（12ヶ月）: {commit_count}件")
            
            # コミット日の取得
            latest_commit = commits[0] if commit_count > 0 else None
            latest_commit_date = latest_commit.commit.author.date if latest_commit else None
            
            # リリース情報を取得
            releases = repo.get_releases()
            recent_releases = [r for r in releases if r.created_at > threshold_date]
            release_count = len(recent_releases)
            
            print(f"リリース数（12ヶ月）: {release_count}件")
            
            # 判定基準
            is_active = False
            reasons = []
            
            if latest_commit_date and latest_commit_date > threshold_date:
                is_active = True
                reasons.append("最終コミットが12ヶ月以内")
            
            if commit_count >= 12:
                is_active = True
                reasons.append(f"コミット数が基準以上（{commit_count}件 ≥ 12件）")
            elif release_count >= 1:
                is_active = True
                reasons.append(f"リリースあり（{release_count}件）")
            
            # 判定結果
            if is_active:
                print(f"判定: ✅ 合格")
            else:
                print(f"判定: ❌ 不合格")
            
            print(f"\n説明: ", end="")
            if is_active:
                print("リポジトリは活発にメンテナンスされています。")
                print(f"理由: {', '.join(reasons)}")
            else:
                print("リポジトリの更新が少ない、または停滞しています。")
                if commit_count < 12:
                    print(f"  - コミット数が少ない（{commit_count}件 < 12件/年）")
                if release_count < 1:
                    print(f"  - リリースがない（{release_count}件）")
            
            # 詳細情報
            print(f"\n【リポジトリ情報】")
            print(f"説明: {repo.description or 'N/A'}")
            print(f"スター数: {repo.stargazers_count}")
            print(f"フォーク数: {repo.forks_count}")
            print(f"ウォッチャー数: {repo.watchers_count}")
            print(f"作成日: {repo.created_at.strftime('%Y-%m-%d')}")
            print(f"主要言語: {repo.language or 'N/A'}")
            
            # 最近のコミット（最新5件）
            print(f"\n【最近のコミット】（最新5件）")
            for i, commit in enumerate(commits[:5], 1):
                commit_date = commit.commit.author.date.strftime('%Y-%m-%d %H:%M:%S')
                commit_msg = commit.commit.message.split('\n')[0][:60]
                print(f"{i}. {commit_date} - {commit_msg}")
            
            # 最近のリリース（最新3件）
            if release_count > 0:
                print(f"\n【最近のリリース】（最新3件）")
                for i, release in enumerate(recent_releases[:3], 1):
                    release_date = release.created_at.strftime('%Y-%m-%d')
                    print(f"{i}. {release.tag_name} ({release_date})")
            
            print('='*70)
            
            return {
                'is_active': is_active,
                'commit_count': commit_count,
                'release_count': release_count,
                'latest_commit_date': latest_commit_date,
                'reasons': reasons
            }
            
        except GithubException as e:
            print(f"\n❌ GitHubエラー: {e.status} - {e.data.get('message', str(e))}")
            if e.status == 404:
                print("リポジトリが見つかりません。URLを確認してください。")
            elif e.status == 403:
                print("レート制限に達しました。しばらく待ってから再試行してください。")
            return None
        except Exception as e:
            print(f"\n❌ エラー: {type(e).__name__} - {str(e)}")
            import traceback
            traceback.print_exc()
            return None

def main():
    """メイン処理"""
    if len(sys.argv) < 2:
        print("使用方法: python check_updates.py <GitHubリポジトリURL>")
        print("例: python check_updates.py https://github.com/apache/httpd")
        sys.exit(1)
    
    repo_url = sys.argv[1]
    github_token = os.environ.get('GITHUB_TOKEN')
    
    checker = GitHubUpdateChecker(github_token)
    result = checker.check_github_updates(repo_url)
    
    if result is None:
        sys.exit(1)
    
    sys.exit(0 if result['is_active'] else 1)

if __name__ == '__main__':
    main()
