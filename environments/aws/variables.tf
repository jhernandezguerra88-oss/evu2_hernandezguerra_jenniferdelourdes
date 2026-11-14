variable "aws_region" {
  description = "Region AWS autorizada"
  type        = string
  default     = "us-east-1"
}

variable "x" {
  description = "N.º de lista X (1 a 254), unico en el laboratorio"
  type        = number
  validation {
    condition     = var.x >= 1 && var.x <= 254
    error_message = "X debe estar entre 1 y 254."
  }
}

variable "curso" {
  description = "Curso con formato cNN (ej. c01)"
  type        = string
  validation {
    condition     = can(regex("^c[0-9]{2}$", var.curso))
    error_message = "El curso debe tener formato cNN."
  }
}

variable "build_ref" {
  description = "Referencia del build/commit que identifica el artefacto (4 a 80 caracteres)"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{4,80}$", var.build_ref))
    error_message = "build_ref debe tener 4 a 80 caracteres: letras, numeros, punto, guion o guion bajo."
  }
}

variable "portal_version" {
  description = "Version del Portal a desplegar (v1 o v2)"
  type        = string
  validation {
    condition     = contains(["v1", "v2"], var.portal_version)
    error_message = "portal_version debe ser v1 o v2."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "capacidad_base" {
  description = "Capacidad base fija (instancias en servicio)"
  type        = number
  default     = 2
}

variable "capacidad_maxima" {
  description = "Capacidad maxima temporal durante el reemplazo"
  type        = number
  default     = 3
}
