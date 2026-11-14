variable "prefix" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnets" {
  description = "Mapa de subredes publicas: cidr y zona de disponibilidad"
  type = map(object({
    cidr = string
    az   = string
  }))
}
