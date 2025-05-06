#############################################
# ACM 証明書設定（CloudFront用）
#
# - CloudFront では us-east-1 リージョンに ACM 証明書が必要
# - DNS 検証方式を利用（Route53 で CNAME レコード自動作成）
# - subject_alternative_names に www サブドメインなど含め可
# - 証明書の有効化（検証完了）まで待機設定あり
#############################################


###########################################
# ACM 証明書の作成
# - ドメイン：var.domain_name
# - サブドメイン：var.subject_alternative_names
# - DNS検証方式
# - us-east-1 固定（CloudFront用）
###########################################
resource "aws_acm_certificate" "website_cert" {
  provider          = aws.us_east_1  # CloudFront用証明書は us-east-1 に必要
  domain_name       = var.domain_name
  validation_method = "DNS"          # DNS検証を指定（Route53でCNAMEレコードを作成）

  subject_alternative_names = var.subject_alternative_names    # www などのサブドメイン

  lifecycle {
    create_before_destroy = true     # 既存証明書が破棄される前に新しい証明書を先に作成
  }
}


###########################################
# ACM 証明書の DNS 検証を待機
#
# - aws_route53_record.cert_validation で作成される
#   CNAME レコードを参照して DNS 検証を自動化
# - CloudFront ディストリビューション作成時に
#   証明書が未検証エラーとならないよう依存関係を明示
###########################################
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.website_cert.arn


  # DNSに作成されたCNAMEレコードのFQDN（例: _abc.example.com）
  validation_record_fqdns = [
   for record in aws_route53_record.cert_validation : record.fqdn
 ]
}
