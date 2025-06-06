#############################################
# メインプロバイダー（東京リージョン）
# - S3バケット、Route 53、CloudWatch などリージョン依存リソース用
#############################################
provider "aws" {
  region = "ap-northeast-1" # 東京リージョン。必要に応じて変更してください。
}


#############################################
# us-east-1プロバイダー（エイリアス付き）
# - CloudFront、ACM（証明書）、WAF（WebACL）用
#   ※ CloudFront は us-east-1（バージニア北部）でのみ ACM証明書が有効
#############################################
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"      # CloudFront / ACM / WAF 用リージョン
}
