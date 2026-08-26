resource "aws_autoscaling_group" "backend" {
  name_prefix               = "${var.project_name}-${var.environment}-backend-asg-"
  vpc_zone_identifier       = var.subnets
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  target_group_arns = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-backend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                      = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.backend.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
  }
}
