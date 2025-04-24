##############################
# ホストゾーンの取得または作成
##############################

# --- 既存ゾーン（Route53で新規取得した場合）
data "aws_route53_zone" "main_zone" {
  count        = var.use_existing_zone ? 1 : 0
  name         = var.zone_name
  private_zone = false
}

# --- 新規作成（他社から移管した場合）
resource "aws_route53_zone" "main_zone" {
  count = var.use_existing_zone ? 0 : 1
  name  = var.zone_name
}

# --- 共通化されたホストゾーンID（local変数）
locals {
  hosted_zone_id = var.use_existing_zone ? data.aws_route53_zone.main_zone[0].zone_id : aws_route53_zone.main_zone[0].zone_id
}


############################################
# ドメイン側のネームサーバー(NS)を更新する処理
# - 他社から移管されたドメインが対象
# - 作成したRoute53ホストゾーンのNSレコードを、ドメインに紐付ける
# - use_existing_zone = false のときのみ有効
############################################
resource "aws_route53domains_registered_domain" "domain_ns_update" {
  count = var.use_existing_zone ? 0 : 1  # 既存ゾーン使用時は処理をスキップ

  domain_name = var.zone_name  # ドメイン名（例: example.com）


  # 新しく作成したホストゾーンのNSレコードを指定（4つまで）
  name_server {
    name = aws_route53_zone.main_zone[0].name_servers[0]
  }

  name_server {
    name = aws_route53_zone.main_zone[0].name_servers[1]
  }

  name_server {
    name = aws_route53_zone.main_zone[0].name_servers[2]
  }

  name_server {
    name = aws_route53_zone.main_zone[0].name_servers[3]
  }
}



###########################################
# SSL証明書検証用のRoute53レコード（for ACM）
###########################################


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.website_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = local.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

###########################################
# CloudFront用Aレコード（www付き）
###########################################


resource "aws_route53_record" "www_alias" {
  zone_id = local.hosted_zone_id
  name    = var.www_record_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
