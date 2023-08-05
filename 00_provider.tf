
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "portfolio-terrafom-bucket"
    key    = "infra"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.main.region
}
