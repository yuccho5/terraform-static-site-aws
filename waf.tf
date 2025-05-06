#############################################
# AWS WAFv2 Web ACL for CloudFront
# 
# - CloudFront ディストリビューションに適用する WAF
# - AWS Managed Rules 3種類を使用
# - デフォルト動作は「許可」
# - CloudWatch メトリクス有効化
#
# 目的：
# - 一般的なWebアプリ攻撃、悪意あるIP、危険な入力のブロック
# - ルール違反時の可視化・監視用メトリクス取得
#############################################
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name        = var.waf_name
  description = var.waf_description
  provider    = aws.us_east_1        # CloudFront用WAFは us-east-1 に作成が必要
  scope       = "CLOUDFRONT"         # CloudFront に適用するWAF


  ###########################################
  # デフォルト動作（ルールにマッチしないリクエスト）：許可
  ###########################################
  default_action {
    allow {}
  }


  ###########################################
  # 可視化設定：
  # - CloudWatchメトリクス出力有効化
  # - サンプルリクエスト取得
  # → ダッシュボード・アラート設定の基盤
  ###########################################
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.waf_name
    sampled_requests_enabled   = true
  }


  ##################################################
  # ルール①: Known Bad Inputs
  # - SQLi, XSS など悪意ある入力を検知・ブロック
  # - マネージドルール：AWSManagedRulesKnownBadInputsRuleSet
  # - 文字列ベースの攻撃対策
  ##################################################
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 0

    override_action {
      none {}         # AWSのルール動作をそのまま使用
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }


  ##################################################
  # ルール②: Amazon IP Reputation List
  # - 悪意あるIPアドレスからのアクセスをブロック
  # - 既知のボットネット、攻撃ホストなどを排除
  ##################################################
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPReputationList"
      sampled_requests_enabled   = true
    }
  }


  ##################################################
  # ルール③: Common Rule Set
  # - 一般的なWebアプリ攻撃を広くカバー
  # - Basic SQLi, XSS, Command Injection など
  ##################################################
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

