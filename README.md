# ソフトウェア審査自動化システム

[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

オープンソースソフトウェア（OSS）の審査を自動化するツールです。  
脆弱性情報と開発活動の活発さを自動でチェックし、導入判断をサポートします。


オープンソースソフトウェア（OSS）の審査を自動化するツールです。  
脆弱性情報と開発活動の活発さを自動でチェックし、導入判断をサポートします。

## 🌟 主な機能

### 1. 脆弱性チェック
- **JVN iPedia API**と連携し、過去5年間の脆弱性情報を検索
- 検出された脆弱性の詳細情報（CVSS評価、影響範囲等）を表示
- 自動判定：脆弱性が0件なら「合格」

### 2. 更新頻度チェック
- **GitHub API**と連携し、リポジトリの活動状況を調査
- 直近12ヶ月のコミット数、リリース数を確認
- 自動判定：コミット数が月1回以上、またはリリースがあれば「合格」

### 3. 統合審査レポート
- 上記2つのチェックを統合し、総合判定を実施
- 詳細レポートを自動生成（テキスト形式）
- バッチ処理で複数ソフトウェアの一括審査が可能

### 4. サマリー集計
- 過去の審査結果を集計してサマリーを表示
- 合格率、脆弱性統計などを可視化

---

## 📋 必要な環境

- **OS**: Linux / macOS / WSL2
- **Python**: 3.8以上
- **bash**: 4.0以上
- **インターネット接続**: JVN iPedia API、GitHub API へのアクセス

---

## 🚀 セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-username/software_audit.git
cd software_audit
