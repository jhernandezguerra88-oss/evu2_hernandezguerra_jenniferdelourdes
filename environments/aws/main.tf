locals {
  alumno = format("a%03d", var.x)
  prefix = "na-u2-${var.curso}-${local.alumno}"

  tags = {
    proyecto  = "NexoAndes"
    fase      = "U2"
    alumno    = local.alumno
    curso     = var.curso
    proveedor = "aws"
  }

  # Parametros del bootstrap docente. Ajustar a las variables reales
  # de la plantilla v2 cuando se reciba.
  portal_user_data = templatefile(
    "${path.module}/templates/user_data_${var.portal_version}.sh.tpl",
    {
      student_name   = var.student_name
      student_number = tostring(var.x)
      environment    = "u2"
      portal_version = var.portal_version
      project_name   = "NexoAndes"
    }
  )
}

module "network" {
  source = "../../modules/aws_network"

  prefix   = local.prefix
  vpc_cidr = "10.${var.x}.0.0/16"
  subnets = {
    a = { cidr = "10.${var.x}.10.0/24", az_index = 0 }
    b = { cidr = "10.${var.x}.20.0/24", az_index = 1 }
  }
}

module "compute" {
  source = "../../modules/aws_compute"

  prefix           = local.prefix
  vpc_id           = module.network.vpc_id
  subnet_ids       = module.network.subnet_ids
  alb_sg_id        = module.network.alb_sg_id
  instance_sg_id   = module.network.instance_sg_id
  instance_type    = var.instance_type
  user_data        = local.portal_user_data
  portal_version   = var.portal_version
  capacidad_base   = var.capacidad_base
  capacidad_maxima = var.capacidad_maxima
}
