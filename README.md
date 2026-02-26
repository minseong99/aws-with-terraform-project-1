# AWS 3-Tier アーキテクチャ設計および構築 (Terraform 完全自動化・FinOps対応)

## プロジェクトの概要
本プロジェクトは、AWS上に可用性・セキュア・コスト最適化を考慮したモダンな3-Tierアーキテクチャを構築したものです。
インフラのプロビジョニングには **Terraform** を用いてIaC（Infrastructure as Code）を完全自動化し、**GitHub Actions** と連携することで、安全かつ効率的なCI/CDパイプラインを実装しています。

### アーキテクチャのイメージ
<img width="1171" height="601" alt="final drawio (1)" src="https://github.com/user-attachments/assets/7c760101-8f81-4007-b1fb-ef900fc4e605" />

---

## 使用技術 (Tech Stack)
* **Cloud Provider:** AWS (VPC, EC2, ALB, Auto Scaling Group, NAT Gateway, S3, IAM)
* **IaC (Infrastructure as Code):** Terraform (~>v1.14.0)
* **CI/CD:** GitHub Actions
* **Security & Auth:** OpenID Connect (OIDC)

---

## アーキテクチャの工夫した点 (Key Highlights)

本プロジェクトでは、単にリソースを作成するだけでなく、**実際の現場（エンタープライズ環境）で求められる要件**に焦点を当てて設計・構築を行いました。

### 1. FinOpsを意識したコスト最適化 (Toggle CI/CD)
* **課題:** 開発環境（Dev）において、使用していない夜間や休日もNAT GatewayやEC2（ASG）が稼働し続けると、無駄なクラウドリソース費用が発生します。
* **解決策:** GitHub Actionsの `workflow_dispatch` を活用し、**「インフラの起動・停止（true/false）」をワンクリックで切り替えられるキルスイッチ（Toggle Pipeline）** を実装しました。Terraformの変数を動的に注入することで、インフラの骨組み（VPC等）は残しつつ、課金対象となるコンピューティングリソースのみを安全に削除・再作成できるようにしています。

### 2. キーレス認証とモダンセキュリティ対策 (OIDC)
* **IAM認証の最適化:** 漏洩リスクのある永続的なアクセスキー（Access Key ID / Secret Key）をGitHubのSecretsに保存するアンチパターンを避け、**OIDC（OpenID Connect）** を導入しました。これにより、実行時のみ有効な一時的なクレデンシャルを発行し、セキュリティを極限まで高めています。


### 3. スケーラビリティと保守性を高めるIaCモジュール化
* Terraformのコードを単一のディレクトリにベタ書きするのではなく、**ビジネスロジック（`modules`）と環境変数（`env/dev`, `env/prod`）を完全に分離**しました。
* DRY（Don't Repeat Yourself）原則を遵守し、将来的な複数環境への横展開（マルチ環境デプロイ）や、Stateファイルの安全な分離（S3 Backend）を容易にするエンタープライズレベルのディレクトリ構成を採用しています。


### 4. `Bootstrap`:事前準備  とセキュアなState管理
* **OIDCとCI/CDの基盤構築**: CI/CDパイプラインを構築するための事前準備として、OIDC連携用のIAM Roleをローカル環境から初期構築（`Bootstrap`）しました。これにより、dev/prod環境への git push をトリガーとして、`validate から plan、apply` までが自動的に実行されるパイプライン（`terraform.yml`）の安全な認証基盤を確立しています。
* **State Lockingの実装**: TerraformのStateファイル（`.tfstate`）を安全に一元管理するため、S3バケットを初期構築しました。さらに、デプロイ時の競合や状態破損を防ぐため（`State Locking`）、DynamoDBテーブルも併せて構築し、堅牢なIaC運用基盤を実現しています。


---

## CI/CD パイプライン構成
GitHub Actionsを用いて、2つの強力なパイプラインを構築し、アジャイルな開発スピードとコスト最適化（FinOps）を両立させています。

### 1. インフラ自動デプロイパイプライン (`terraform.yml`)
インフラの変更を迅速かつ自動的に反映させるアジャイルなデプロイフローです。
* **完全自動化されたデプロイフロー:** 対象ブランチ（`develop` または `main`）への `git push` をトリガーとして、`terraform validate` による構文チェック、`plan` による変更確認、そして `apply -auto-approve` によるインフラの構築・反映までがワンストップで自動実行されます。
* **動的ディレクトリ割り当て:** 実行されるブランチに応じて、Terraformの `working-directory` を動的に切り替えるロジックを実装しています。これにより、`develop` ブランチの変更は `env/dev`（開発環境）へ、`main` ブランチの変更は `env/prod`（本番環境）へと正確に自動デプロイされます。

### 2. コスト最適化用キルスイッチ (`toggle.yml`)
使用していない時間帯（夜間や休日など）の無駄なクラウドリソース費用を完全に防ぐためのパイプラインです。
* **手動トリガーによるリソース管理:** `workflow_dispatch` を利用し、任意のタイミングでGitHub上のUIから「インフラの起動・停止」をワンクリックで実行可能です。
* **FinOpsの実践:** Terraformの変数（`enable-compute=false`, `enable-nat-gateway` 等）を外部から動的に注入することで、VPCやS3などの基盤（無料枠や低コストリソース）は維持したまま、課金対象となるNAT GatewayやASG（EC2）、Bastion Hostのみを安全に一括削除・再作成できる仕組みを構築しました。

---

## ディレクトリ構成
```text
📦 my-portfolio-project
 ┣ 📂 .github
 ┃ ┗ 📂 workflows
 ┃   ┣ 📜 toggle.yml        # コスト最適化用：インフラ起動・停止のToggleスイッチ
 ┃   ┗ 📜 terraform.yml     # CI/CD パイプライン：ブランチ戦略に基づくインフラ自動構築
 ┣ 📂 bootstrap               # CI/CD基盤およびState管理リソースの初期構築 (Bootstrap)
 ┃   ┣ 📜 backend_storage.tf  # Stateファイルを安全に保管するS3バケット＆DynamoDB (Locking)
 ┃   ┗ 📜 oidc.tf             # GitHub Actions連携用のOIDC IAM Role
 ┣ 📂 modules                 # インフラの設計図（共通モジュール）
 ┃ ┗ 📂 project1_infra
 ┃   ┣ 📜 vpc.tf
 ┃   ┣ 📜 sg.tf               # Security Group
 ┃   ┣ 📜 compute.tf          # Bastion Host, Launch Template, ASG
 ┃   ┣ 📜 alb.tf              
 ┃   ┣ 📜 iam.tf              # S3にアクセスするEC2用IAM Role
 ┃   ┣ 📜 endpoint.tf         # S3 Gateway Endpoint (NAT費用削減用)
 ┃   ┣ 📜 variables.tf
 ┃   ┣ 📜 locals.tf
 ┃   ┗ 📜 versions.tf         # Terraform & Provider バージョン固定
 ┣ 📂 env                     # 環境ごとのステートと変数（注文書）
 ┃ ┣ 📂 dev
 ┃ ┃ ┣ 📜 main.tf             # 開発環境用デプロイ設定
 ┃ ┃ ┗ 📜 variables.tf        # 開発環境用の変数入力
 ┃ ┗ 📂 prod
 ┃   ┣ 📜 main.tf             # 本番環境用デプロイ設定
 ┃   ┗ 📜 variables.tf        # 本番環境用の変数入力
