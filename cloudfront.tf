#############################################
# CloudFront ディストリビューション設定
#
# - 静的ウェブサイト (S3バケット) を CloudFront 経由で公開
# - カスタムドメイン + HTTPS + WAF に対応
# - OAC (Origin Access Control) による署名付きアクセス
#
# → 静的ウェブサイトのセキュアなCDN構成
#############################################
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website for ${var.domain_name}"
  default_root_object = "index.html"

  ###########################################
  # WAF WebACL を適用（セキュリティルール）
  # - us-east-1 に作成した WebACL を関連付け
  ###########################################
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn


  ###########################################
  # オリジン設定
  # - S3 バケット (OAC 経由アクセス) をオリジンとして指定
  # - origin_access_control_id により OAC を有効化
  ###########################################
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "s3-website-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }  


  ###########################################
  # デフォルトキャッシュビヘイビア
  # - GET / HEAD のみ許可
  # - クエリパラメータ・Cookie は転送しない
  # - HTTPアクセスはHTTPSへリダイレクト
  ###########################################
  default_cache_behavior {
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "s3-website-origin"
  
      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }
  
      viewer_protocol_policy = "redirect-to-https"
    }


  ###########################################
  # 証明書検証完了を待つ
  # - ACM 証明書の検証が完了するまで CloudFront 作成を遅延
  # - depends_on により明示的に依存関係を定義
  ###########################################
  depends_on = [
  aws_acm_certificate.website_cert,
  aws_acm_certificate_validation.cert_validation
  ]

 
  ###########################################
  # HTTPS 証明書設定
  # - us-east-1 に発行した ACM 証明書を指定
  # - TLSバージョンは v1.2_2021 以上を要求
  ###########################################
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }


  ###########################################
  # 地域制限なし（全世界に公開）
  ###########################################
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  ###########################################
  # カスタムドメイン設定
  # - var.aliases に FQDN のリストを指定
  ###########################################
  aliases = var.aliases


  ###########################################
  # タグ（CloudFront コンソール上の表示用）
  ###########################################
  tags = {
    Name = "WebsiteDistribution"
  }
}


#############################################
# Origin Access Control (OAC)
#
# - CloudFront から S3 バケットへの署名付きアクセス
# - CloudFront 経由のみ S3 にアクセスを許可
# - static website hosting 無効化 + OAC の組み合わせ
#############################################
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "OAC for S3 Website"
  description                       = "Access control for S3 static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
