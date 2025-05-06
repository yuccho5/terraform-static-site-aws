#############################################
# Route53 ホストゾーン & レコード設定
#
# - 既存ホストゾーン（use_existing_zone = true）にも対応
# - 新規ホストゾーン作成（use_existing_zone = false）の場合
#   → NSレコード更新も自動化
# - ACM 証明書検証用レコードを自動作成
# - CloudFront の ALIAS レコード（Aレコード）作成
#
# → Route53 の DNS 構成を動的に選択＆自動化
#############################################


##############################
# ホストゾーンの取得または作成
##############################
# --- 既存ゾーン（Route53で新規取得した場合）
# - 既存ホストゾーンIDを取得
data "aws_route53_zone" "main_zone" {
  count        = var.use_existing_zone ? 1 : 0
  name         = var.zone_name
  private_zone = false
}

# --- 新規作成（他社から移管した場合）
# - Route53 に新規ホストゾーンを作成
resource "aws_route53_zone" "main_zone" {
  count = var.use_existing_zone ? 0 : 1
  name  = var.zone_name
}

# --- 共通化されたホストゾーンID（local変数）
# → data or resource の結果を切り替え
locals {
  hosted_zone_id = var.use_existing_zone ? data.aws_route53_zone.main_zone[0].zone_id : aws_route53_zone.main_zone[0].zone_id
}


############################################
# ドメイン側のネームサーバー(NS)更新
#
# - use_existing_zone = false の場合のみ実行
# - 他社管理ドメインのNSを Route53 に切り替え
# - Route53ゾーンのNSレコード（4つ）を登録
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


#############################################
# SSL証明書検証用 Route53 レコード
#
# - ACM 証明書の DNS 検証に必要な CNAME レコードを作成
# - aws_acm_certificate.website_cert の domain_validation_options に基づく
# - for_each により複数ドメイン（SAN含む）対応
#############################################
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


#############################################
# CloudFront 用 ALIAS レコード（Aレコード）
#
# - www サブドメイン用 A レコード（ALIAS）
# - CloudFront ディストリビューションに紐付け
# - CloudFront 側の DNS 名 & Zone ID を指定
#############################################
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
