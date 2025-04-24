###########################################
# ACM 証明書の作成（CloudFront用、us-east-1）
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
# DNS検証の完了を待機するリソース（明示的に依存）
# → これがあることで CloudFront 等が検証完了後に続く
###########################################
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.website_cert.arn


  # DNSに作成されたCNAMEレコードのFQDN（例: _abc.example.com）
  validation_record_fqdns = [
   for record in aws_route53_record.cert_validation : record.fqdn
 ]
}
