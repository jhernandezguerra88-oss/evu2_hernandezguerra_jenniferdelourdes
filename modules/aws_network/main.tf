resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11:Flow logs fuera del alcance de la Fase U2 (requieren destino y rol dedicados); mejora documentada
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.prefix}-aws-vpc" }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.prefix}-aws-default-sg" }
}

resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Subredes publicas por diseno (Anexo 1): el bootstrap requiere IP publica e Internet Gateway
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.prefix}-aws-subnet-${each.key}" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.prefix}-aws-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.prefix}-aws-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  #checkov:skip=CKV_AWS_260:Portal publico por HTTP 80 por diseno (Anexo 1); la verificacion independiente es externa
  name        = "${var.prefix}-aws-alb-sg"
  description = "HTTP desde Internet hacia el ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Hacia las instancias"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.prefix}-aws-alb-sg" }
}

resource "aws_security_group" "instance" {
  name        = "${var.prefix}-aws-ec2-sg"
  description = "HTTP solo desde el ALB; sin SSH"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "HTTPS para paquetes y bootstrap"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP para repositorios de paquetes"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.prefix}-aws-ec2-sg" }
}
