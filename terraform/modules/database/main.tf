resource "aws_ebs_volume" "postgres_data" {
  availability_zone = var.availability_zone
  size              = var.database_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-postgres-data"
    Component = "database"
  })
}

resource "aws_instance" "postgres" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user-data.sh", {
    db_name          = var.database_name
    db_user          = var.database_user
    db_password      = var.database_password
    postgres_version = "14"
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-database"
    Component = "database"
  })

  depends_on = [aws_ebs_volume.postgres_data]
}

resource "aws_volume_attachment" "postgres_data_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.postgres_data.id
  instance_id = aws_instance.postgres.id
}
