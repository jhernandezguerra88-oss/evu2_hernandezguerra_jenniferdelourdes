output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_ids" {
  value = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id]
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "instance_sg_id" {
  value = aws_security_group.instance.id
}
