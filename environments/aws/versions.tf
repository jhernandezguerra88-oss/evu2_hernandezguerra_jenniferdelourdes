terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # Backend en el root efectivo (corrige U1). Bucket y region se
  # entregan con terraform init -backend-config (ver README).
  backend "s3" {
    key          = "u2/aws/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
