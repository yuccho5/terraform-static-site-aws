resource "aws_cloudwatch_dashboard" "cloudfront_dashboard" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
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

# SNSトピックを作成
resource "aws_sns_topic" "cloudfront_alert_topic" {
  provider = aws.us_east_1
  name     = var.sns_topic_name
}

# メール購読者を追加（メールアドレスを適宜変更）
resource "aws_sns_topic_subscription" "cloudfront_email_subscription" {
  provider = aws.us_east_1
  topic_arn = aws_sns_topic.cloudfront_alert_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}


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
  treat_missing_data  = "notBreaching"
 
  alarm_actions = [
    aws_sns_topic.cloudfront_alert_topic.arn
  ]
}

