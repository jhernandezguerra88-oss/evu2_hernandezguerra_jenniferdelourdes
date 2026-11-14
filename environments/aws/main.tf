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

  # Artefacto docente unico para v1 y v2: la version solo cambia el valor
  # portal_version, y el propio bootstrap instala un release distinto.
  # x debe ser numero (el bootstrap valida tipo entero).
  portal_user_data = templatefile(
    "${path.module}/templates/user_data_u2.sh.tpl",
    {
      provider       = "aws"
      x              = var.x
      student        = local.alumno
      course         = var.curso
      build_ref      = var.build_ref
      portal_version = var.portal_version
    }
  )
}

module "network" {
  source = "../../modules/aws_network"

  prefix   = local.prefix
  vpc_cidr = "10.${var.x}.0.0/16"
  subnets = {
    a = { cidr = "10.${var.x}.10.0/24", az = "${var.aws_region}a" }
    b = { cidr = "10.${var.x}.20.0/24", az = "${var.aws_region}b" }
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
