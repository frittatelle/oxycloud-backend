terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.22.0"
    }
  }
}

module "website" {
  source = "./website"

  bucket_prefix = "oxy-website-"
}

provider "aws" {
  region = var.region
}
