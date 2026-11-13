variable "prefix" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnets" {
  description = "Mapa de subredes publicas: cidr e indice de zona"
  type = map(object({
    cidr     = string
    az_index = number
  }))
}
