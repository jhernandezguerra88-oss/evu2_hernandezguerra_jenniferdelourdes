data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.prefix}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = base64encode(var.user_data)

  vpc_security_group_ids = [var.instance_sg_id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 obligatorio
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.prefix}-ec2"
      version = var.portal_version
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "this" {
  name               = substr("${var.prefix}-alb", 0, 32)
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
  tags               = { Name = "${var.prefix}-alb" }
}

resource "aws_lb_target_group" "this" {
  name     = substr("${var.prefix}-tg", 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  deregistration_delay = 30
  tags                 = { Name = "${var.prefix}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.prefix}-asg"
  min_size            = var.capacidad_base
  desired_capacity    = var.capacidad_base
  max_size            = var.capacidad_maxima
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.this.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  # Reemplazo rolling: nunca baja de la capacidad base declarada.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 150
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-ec2"
    propagate_at_launch = true
  }
}
