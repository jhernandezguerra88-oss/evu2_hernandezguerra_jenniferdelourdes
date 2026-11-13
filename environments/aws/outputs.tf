output "alumno" {
  value = local.alumno
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "endpoint" {
  value = "http://${module.compute.alb_dns_name}/"
}

output "asg_name" {
  value = module.compute.asg_name
}

output "launch_template_id" {
  value = module.compute.launch_template_id
}

output "launch_template_version" {
  value = module.compute.launch_template_version
}

output "portal_version" {
  value = var.portal_version
}
