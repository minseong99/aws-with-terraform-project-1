<img width="1221" height="601" alt="제목 없는 다이어그램 drawio" src="https://github.com/user-attachments/assets/cd9769a8-6f06-49c9-816c-f1a833a7dbe0" /># AWS 3-Tier アーキテクチャ設計および構築 (Terraform 完全自動化・FinOps対応)

## プロジェクトの概要
本プロジェクトは、AWS上に可用性・セキュア・コスト最適化を考慮したモダンな3-Tierアーキテクチャを構築したものです。
インフラのプロビジョニングには **Terraform** を用いてIaC（Infrastructure as Code）を完全自動化し、**GitHub Actions** と連携することで、安全かつ効率的なCI/CDパイプラインを実装しています。

さらに、本基盤は　**コンテナ化されたアプリケーション（別リポジトリで管理）を全自動で受け入れるための統合基盤（Project 3フェーズ）**　として設計されています。インフラ（Terraform）とアプリケーション（Docker/CI/CD）の関心を完全に分離し、モダンなDevOps運用を実現しています。

> **Application Repository (Project 2):** [https://github.com/minseong99/Monitoring-docker-project-2]
> コンテナとEC2インスタンスの監視システム（Docker/Grafana/cAdvisor/node-exporter/nginx/prometheus）および、SSMを利用した本インフラへの自動デプロイパイプラインのコードはこちらのリポジトリで管理しています。


### アーキテクチャのイメージ
<img width="1221" height="601" alt="1 drawio" src="https://github.com/user-attachments/assets/bb160cc4-4dd7-4359-9863-62535cf9d4ce" />



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

### 5. 「関心の分離」によるアプリとインフラの別々のデプロイ
* **課題:** インフラのコードとアプリケーションのコードを同一リポジトリ・同一パイプラインで管理すると、アプリの軽微な修正でインフラ全体が意図せず変更されるリスクや、デプロイ時間の増加を招きます。
* **解決策:** インフラ（このリポジトリ）とアプリケーション[https://github.com/minseong99/Monitoring-docker-project-2] のリポジトリを完全に分割しました。Terraformの `user_data` では、OSの初期設定と必須ツール（Docker/Git）のインストールのみを実行します。アプリケーショの最新化やコンテナの起動は、別リポジトリのGitHub Actionsが **AWS Systems Manager (SSM) Run Command** を通じて、SSHポート（22番）を一切開けずにプライベートサブネット内のEC2へ安全にPull型デプロイを行うセキュアなアーキテクチャを実現しました。

### 6. ALB環境下におけるステートフルアプリケーションの運用課題解決
* **課題:** ALB（ロードバランサー）の背後にGrafanaなどの「ログイン状態（セッション）を持つステートフルなアプリケーション」を複数ノード（ASG）で配置した際、ALBのラウンドロビンによるリクエストの振り分けやIPの変動により、セッションが断絶し「ログインループ（Unauthorizedエラー）」が発生しました。
* **解決策（トラブルシューティング）:**
  コンテナ内のログをSSMセッションマネージャーから直接解析し(`docker compose logs grafana`)、認証自体は成功しているものの、ノードの切り替わりによるセッションの不整合が原因であると特定しました。
  これを解決するため、Terraform側でALBのTarget Groupに **Sticky Session（スティッキーセッション）** を有効化してユーザーとノードを固定し、同時にアプリケーションのNginx設定にて `X-Forwarded-For` ヘッダーを用いて正しいクライアントIPをGrafanaに透過させることで、見事にエラーを解消しました。


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
