variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "instance_sg_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "user_data" {
  type = string
}

variable "portal_version" {
  type = string
}

variable "capacidad_base" {
  type = number
}

variable "capacidad_maxima" {
  type = number
}
