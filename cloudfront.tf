#########################################
# CloudFront ディストリビューション
# - S3 バケットをオリジンとする静的サイトの公開
# - カスタムドメイン + HTTPS + WAF 対応
#########################################
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static website for ${var.domain_name}"
  default_root_object = "index.html"

  # WAF WebACL の関連付け（us-east-1）
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn


#############################
# オリジン設定：S3 + OAC を使用 
#############################
origin {
  domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
  origin_id                = "s3-website-origin"
  origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
}  

###################################### 
# キャッシュビヘイビア：GET/HEADのみ許可 
######################################
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



##############################################  
# 証明書検証が完了するまで CloudFront 作成を待機
##############################################
  depends_on = [
  aws_acm_certificate.website_cert,
  aws_acm_certificate_validation.cert_validation
]

 

##############################################  
#HTTPS 証明書設定（ACM）
##############################################
 viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }



##############################################  
#地域制限（なし）
##############################################
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


##############################################  
#カスタムドメイン（example.com, www.example.comなど）
##############################################
  aliases = var.aliases


##############################################  
#タグ（CloudFrontに表示される名前など）
##############################################
  tags = {
    Name = "WebsiteDistribution"
  }
}


#########################################
# Origin Access Control（OAC）
# - CloudFrontからS3への署名付きアクセス許可
#########################################
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "OAC for S3 Website"
  description                       = "Access control for S3 static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
