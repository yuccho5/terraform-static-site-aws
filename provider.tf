provider "aws" {
  region = "ap-northeast-1" # 東京リージョン。必要に応じて変更してください。
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"      # CloudFront関連（ACM, WAF）用
}
