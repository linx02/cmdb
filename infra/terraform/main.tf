provider "aws" {
  region = var.aws_region
}

# --- Security Group för EC2 instanserna ---
resource "aws_security_group" "app_sg" {
  name        = "cmdb-sg"
  description = "HTTP"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allt utgående
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Security Group för RDS MySQL ---
resource "aws_security_group" "db_sg" {
  name        = "cmdb-db-sg"
  description = "MySQL"
  vpc_id      = var.vpc_id

  # MySQL (endast från app för extra säkerhet)
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  # Allt utgående
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- MySQL på AWS RDS ---
resource "aws_db_subnet_group" "main" {
  name       = "cmdb-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "mysql" {
  identifier              = "cmdb-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "root"
  password                = "superhemligtlosen"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
}

# --- Launch Template ---
locals {
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    db_url  = "jdbc:mysql://${aws_db_instance.mysql.endpoint}/cmdb?createDatabaseIfNotExist=true"
    db_user = "root"
    db_pass = "superhemligtlosen"
  })
}

resource "aws_launch_template" "app" {
  name_prefix   = "cmdb-launch-"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name = "linx-key"

  user_data = base64encode(local.user_data)

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  depends_on = [aws_db_instance.mysql]
}

# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "cmdb-instance"
    propagate_at_launch = true
  }
}

# --- Load Balancer ---
resource "aws_lb" "app_lb" {
  name               = "cmdb-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "app_tg" {
  name     = "cmdb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# --- Lägg till ASG på Target Group ---
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  lb_target_group_arn   = aws_lb_target_group.app_tg.arn
}

# --- Auto Scaling Policy ---
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# Om CPU % är över 70 under 2 minuter triggas uppskalning
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

output "app_url" {
  description = "URL:et till appen"
  value       = "http://${aws_lb.app_lb.dns_name}"
}