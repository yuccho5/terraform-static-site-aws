#############################################
# S3 バケット設定（静的ウェブサイトホスティング用）
#
# - CloudFront オリジンとして利用
# - OAC（Origin Access Control）によるプライベートアクセス
# - 公開ブロック設定済み（直接アクセス防止）
# - CloudFront 署名付きアクセスのみ許可
#############################################

#########################
# S3 バケット作成
# - バケット名：var.bucket_name
# - タグ：環境名、バケット名
#########################
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "WebsiteBucket"
    Environment = var.environment
  }
}


#########################
# バケット所有権設定
# - object_ownership = "BucketOwnerPreferred"
# → オブジェクトの所有権をバケット所有者優先
#########################
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


#########################
# パブリックアクセス制御
# - 全てのパブリックアクセス設定をブロック
# → CloudFront経由以外の直接アクセス防止
#########################
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#########################
# バケットポリシー設定
# - CloudFront の OAC (Origin Access Control) からの
#   署名付きリクエストのみ S3 GetObject を許可
# - 直接ブラウザアクセスは禁止
#########################
resource "aws_s3_bucket_policy" "s3_oac_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })
}

