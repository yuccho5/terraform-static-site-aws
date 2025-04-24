# Terraform Static Website on AWS

このリポジトリは、Terraform を使用して AWS 上に静的ウェブサイトを構築するインフラ構成を管理します。  
CloudFront を使った HTTPS 配信、S3 バケットへのオリジン制御、WAF によるセキュリティ強化、CloudWatch による監視などを含みます。

---

##  主な構成サービス

- **Amazon S3**：HTML/CSS/JS をホストする静的サイト用バケット
- **CloudFront**：グローバルCDN配信、HTTPS対応
- **ACM (AWS Certificate Manager)**：SSL証明書の発行と検証（DNS検証）
- **Route 53**：ドメイン管理とDNS設定（既存または移管）
- **WAFv2**：CloudFront向けマネージドルール
- **CloudWatch**：エラーレート監視と SNS アラート通知
- **SNS**：エラー時のメール通知

---

##  ファイル構成

```text
 ├── provider.tf        	 # プロバイダ定義（東京リージョン + バージニア北
 ├── s3.tf			 # S3バケットとバケットポリシ
 ├── cloudfront.tf		 # CloudFrontとOACの設定
 ├── acm.tf			 # ACM証明書の発行とDNS検証
 ├── route53.tf			 # ホストゾーンの作成/取得とDNSレコード設定
 ├── waf.tf			 # CloudFront用WAFのルール定義
 ├── cloudwatch.tf		 # CloudWatchダッシュボードとアラーム通知設
 ├── variables.tf		 # すべての変数定義
 ├── terraform.tfvars.example	 # 本番やステージングで使えるサンプル変数ファイル
 └── README.md 
```

##  使用方法


### 1. 事前準備

- Route 53でドメインを取得済み、または移管済みであること
- CloudShell または AWS CLI 環境で作業


### 2. 環境構築

```bash
terraform init
terraform plan -var-file=staging.tfvars -out=staging.tfplan
terraform apply "staging.tfplan"
```

### 3. 削除

```bash
terraform destroy -var-file=staging.tfvars
```

### 4. HTML/CSS/JS のアップロード（手動）

Terraform では S3 バケットの作成とアクセス設定のみを行います。
**静的ファイル（index.html など）は手動で S3 にアップロードしてください。**


###  注意点

ACM証明書のDNS検証には少し時間がかかる場合があります。
移管ドメインのNSレコード更新は自動化済（aws_route53domains_registered_domain を使用）です。


###  メール通知（SNS）

初回実行時、通知用メールアドレスに SNS 購読確認メールが届きます。
必ず承認 してください。承認されないと CloudWatch アラームが通知されません。


###  WAF

AWS Managed Rules（3種類）をCloudFrontに適用：

・Known Bad Inputs
・Amazon IP Reputation List
・Common Rule Set


###  補足

terraform apply に失敗した場合は depends_on を確認してください（証明書検証待機など）。
CloudFrontの更新は時間がかかる場合があります（最大15分ほど）。


###  ライセンス

このリポジトリは [MIT License](https://opensource.org/licenses/MIT) のもとで公開されています。

