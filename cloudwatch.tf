#############################################
# CloudWatch Dashboard ＆ アラート設定（CloudFront）
#
# - CloudFront のエラーレートとリクエスト数を可視化
# - TotalErrorRate に対するアラートと通知（SNS + Email）
# - us-east-1 リージョンで CloudFront 関連を監視
#############################################

#########################
# CloudWatch ダッシュボード
# - CloudFrontのエラーレート/リクエスト数を表示
# - us-east-1 は CloudFront メトリクスの統一リージョン
#########################
resource "aws_cloudwatch_dashboard" "cloudfront_dashboard" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      # ウィジェット1：CloudFront エラーレート（全体・4xx・5xx）
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 24,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/CloudFront", "TotalErrorRate", "DistributionId", aws_cloudfront_distribution.website_distribution.id, "Region", "Global" ],
            [ ".", "4xxErrorRate", ".", ".", ".", "." ],
            [ ".", "5xxErrorRate", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Average",
          region = "us-east-1",
          title  = "CloudFront Error Rates"
        }
      },

      # ウィジェット2：CloudFront 総リクエスト数
      {
        type = "metric",
        x    = 0,
        y    = 7,
        width = 24,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.website_distribution.id, "Region", "Global" ]
          ],
          period = 300,
          stat   = "Sum",
          region = "us-east-1",
          title  = "CloudFront Requests (Total)"
        }
      }
    ]
  })
}

#########################
# SNS トピック：アラーム通知用
# - アラームが発火した際の通知送信用
#########################
resource "aws_sns_topic" "cloudfront_alert_topic" {
  provider = aws.us_east_1
  name     = var.sns_topic_name
}


#########################
# SNS サブスクリプション（メール）
# - 通知先メールアドレスを設定
# - terraform apply 後に手動でメール確認・承認が必要
#########################
resource "aws_sns_topic_subscription" "cloudfront_email_subscription" {
  provider = aws.us_east_1
  topic_arn = aws_sns_topic.cloudfront_alert_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}


#########################
# CloudWatch アラーム設定（TotalErrorRate）
# - エラーレートが5%以上 × 3回連続で発生 → SNS通知
# - treat_missing_data = "notBreaching" により誤検知回避
#########################
resource "aws_cloudwatch_metric_alarm" "cloudfront_total_error_alarm" {
  provider = aws.us_east_1 

  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"  # 「以上」
  evaluation_periods  = 3                                 # 評価回数：3回
  threshold           = 5                                 # しきい値：5%
  metric_name         = "TotalErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300                               # 評価期間：5分
  statistic           = "Average"

  datapoints_to_alarm = 3                                 # 3回中3回を満たす場合のみアラーム

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website_distribution.id
    Region         = "Global"
  }

  alarm_description   = "Triggers when CloudFront TotalErrorRate is >= 5% for 15 minutes (3/3)."
  treat_missing_data  = "notBreaching"  # データ欠損時の誤検知防止
  alarm_actions = [
    aws_sns_topic.cloudfront_alert_topic.arn
  ]
}

