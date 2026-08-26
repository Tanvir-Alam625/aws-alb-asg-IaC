resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm if ALB 5xx count is too high"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "asg_capacity" {
  alarm_name          = "${var.project_name}-${var.environment}-asg-capacity"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm when ASG drops below healthy in-service capacity"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = var.common_tags
}
