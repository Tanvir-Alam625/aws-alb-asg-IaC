output "launch_template_id" {
  value = aws_launch_template.backend.id
}

output "launch_template_version" {
  value = aws_launch_template.backend.latest_version
}
