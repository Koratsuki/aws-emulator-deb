terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  # El emulador no implementa todas las validaciones previas del provider.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # S3 en emuladores requiere estilo de ruta (path-style).
  s3_use_path_style = true

  endpoints {
    s3       = var.endpoint_url
    dynamodb = var.endpoint_url
    iam      = var.endpoint_url
    sqs      = var.endpoint_url
    lambda   = var.endpoint_url
    ec2      = var.endpoint_url
    ssm      = var.endpoint_url
    sts      = var.endpoint_url
  }
}

# Recurso de ejemplo. Eliminalo o adaptalo a tus necesidades.
resource "aws_s3_bucket" "example" {
  bucket        = var.example_bucket_name
  force_destroy = true
}
