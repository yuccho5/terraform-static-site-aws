
# --- S3用 ---
variable "bucket_name" {
  type        = string
  description = "S3バケット名（環境ごとに切り替え）"
}

variable "environment" {
  type        = string
  description = "環境名タグ（例：Production、Stagingなど）"
}


# --- ACM 用 ---
variable "domain_name" {
  type        = string
  description = "ACMのメインドメイン名（例: example.com）"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "ACM証明書に追加するサブドメイン（SAN）"
}


# --- CloudFront 用 ---
variable "aliases" {
  type        = list(string)
  description = "CloudFrontのカスタムドメイン（本番・ステージングで切り替え）"
}


# --- Route53 用 ---
variable "zone_name" {
  type        = string
  description = "Route53ホストゾーンの名前（例: example.com）"
}

variable "www_record_name" {
  type        = string
  description = "CloudFrontのAレコードとして登録するFQDN（www付き）"
}


# --- Route53 ゾーンの扱い切替用 ---
variable "use_existing_zone" {
  type        = bool
  description = "既存のRoute53ホストゾーンを使う場合は true、Terraformで新規作成する場合は false"
}


# --- WAF 用 ---
variable "waf_name" {
  type        = string
  description = "WAF WebACLの名前"
}

variable "waf_description" {
  type        = string
  description = "WAF WebACLの説明"
}


# --- CloudWatch 用 ---
variable "dashboard_name" {
  type        = string
  description = "CloudWatch ダッシュボード名"
  default     = "cloudfront-dashboard"
}

variable "alarm_name" {
  type        = string
  description = "CloudWatchアラーム名"
  default     = "cloudfront-total-error-rate-alarm"
}

variable "notification_email" {
  type        = string
  description = "SNS通知用のメールアドレス"
}


# --- SNS用 ---
variable "sns_topic_name" {
  type        = string
  description = "SNSトピック名（例：cloudfront-alert-topic-stg など）"
}
