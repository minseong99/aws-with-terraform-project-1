# AWS 3-Tier アーキテクチャ設計および構築 (Terraform 完全自動化・FinOps対応)

## 📌 プロジェクトの概要
本プロジェクトは、AWS上に可用性・セキュア・コスト最適化を考慮したモダンな3-Tierアーキテクチャを構築したものです。
インフラのプロビジョニングには **Terraform** を用いてIaC（Infrastructure as Code）を完全自動化し、**GitHub Actions** と連携することで、安全かつ効率的なCI/CDパイプラインを実装しています。

### アーキテクチャのイメージ
<img width="1171" height="601" alt="final drawio (1)" src="https://github.com/user-attachments/assets/7c760101-8f81-4007-b1fb-ef900fc4e605" />

---

## 🛠 使用技術 (Tech Stack)
* **Cloud Provider:** AWS (VPC, EC2, ALB, Auto Scaling Group, NAT Gateway, S3, IAM, SSM)
* **IaC (Infrastructure as Code):** Terraform (v1.x.x)
* **CI/CD:** GitHub Actions
* **Security & Auth:** OpenID Connect (OIDC), AWS Systems Manager (SSM) Session Manager

---

## 💡 アーキテクチャの工夫した点 (Key Highlights)

本プロジェクトでは、単にリソースを作成するだけでなく、**「実際の現場（エンタープライズ環境）で求められる要件」**に焦点を当てて設計・構築を行いました。

### 1. 💰 FinOpsを意識したコスト最適化 (Toggle CI/CD)
* **課題:** 開発環境（Dev）において、使用していない夜間や休日もNAT GatewayやEC2（ASG）が稼働し続けると、無駄なクラウドリソース費用が発生します。
* **解決策:** GitHub Actionsの `workflow_dispatch` を活用し、**「インフラの起動・停止（true/false）」をワンクリックで切り替えられるキルスイッチ（Toggle Pipeline）** を実装しました。Terraformの変数を動的に注入することで、インフラの骨組み（VPC等）は残しつつ、課金対象となるコンピューティングリソースのみを安全に削除・再作成できるようにしています。

### 2. 🔐 キーレス認証とモダンセキュリティ対策 (OIDC & SSM)
* **IAM認証の最適化:** 漏洩リスクのある永続的なアクセスキー（Access Key ID / Secret Key）をGitHubのSecretsに保存するアンチパターンを避け、**OIDC（OpenID Connect）** を導入しました。これにより、実行時のみ有効な一時的なクレデンシャルを発行し、セキュリティを極限まで高めています。
* **踏み台サーバーとSSMのハイブリッド運用:** 従来のSSH（ポート22番）への依存を減らし、Private Subnet内のEC2へのアクセスは **SSM Session Manager** を標準としています。ただし、将来的なデータベース（RDS）への安全なGUI接続（SSHトンネリング）を見据え、最小構成のBastion Hostを配置する実務的なハイブリッド構成を採用しています。

### 3. 🏗 スケーラビリティと保守性を高めるIaCモジュール化
* Terraformのコードを単一のディレクトリにベタ書きするのではなく、**ビジネスロジック（`modules`）と環境変数（`env/dev`, `env/prod`）を完全に分離**しました。
* DRY（Don't Repeat Yourself）原則を遵守し、将来的な複数環境への横展開（マルチ環境デプロイ）や、Stateファイルの安全な分離（S3 Backend）を容易にするエンタープライズレベルのディレクトリ構成を採用しています。

---

## 🚀 CI/CD パイプライン構成
GitHub Actionsを用いて、インフラの変更を安全かつ迅速に反映させるフローを構築しています。

* **自動フォーマット＆検証:** Push時に `terraform fmt` および `terraform validate` を実行。
* **動的ディレクトリ割り当て:** 実行されるブランチ（`main` または `develop` 等）に応じて、Terraformの `working-directory` を自動的に切り替えるロジックを実装しています。
* **安全な反映:** `terraform plan` の結果をPR（Pull Request）上で確認後、マージ時に自動で `apply` される安全なデプロイフローを想定しています。

---

## 📁 ディレクトリ構成
```text
📦 my-portfolio-project
 ┣ 📂 .github
 ┃ ┗ 📂 workflows
 ┃   ┗ 📜 toggle.yml        # CI/CD パイプライン（OIDC認証・Toggleスイッチ）
 ┣ 📂 modules               # インフラの設計図（共通モジュール）
 ┃ ┗ 📂 project1_infra
 ┃   ┣ 📜 vpc.tf
 ┃   ┣ 📜 asg.tf
 ┃   ┣ 📜 alb.tf
 ┃   ┣ 📜 endpoint.tf       # S3 Gateway Endpoint (NAT費用削減)
 ┃   ┗ 📜 variables.tf
 ┣ 📂 env                   # 環境ごとのステートと変数（注文書）
 ┃ ┣ 📂 dev
 ┃ ┃ ┗ 📜 main.tf           # 開発環境用デプロイ設定
 ┃ ┗ 📂 prod
 ┃   ┗ 📜 main.tf           # 本番環境用デプロイ設定
