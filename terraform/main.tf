terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Archivos que genera el emulador en cada arranque.
  emulator_dir = abspath("${path.module}/../.aws/emulator/9297")
}

provider "aws" {
  region = var.region

  # Credenciales y perfil que genera el emulador. No hace falta exportar
  # AWS_ACCESS_KEY_ID ni AWS_SECRET_ACCESS_KEY en la terminal.
  shared_credentials_files = ["${local.emulator_dir}/emulator_credentials"]
  shared_config_files      = ["${local.emulator_dir}/config"]
  profile                  = var.profile

  # El emulador usa un certificado autofirmado. custom_ca_bundle apunta
  # a la ruta del host, no a la ruta interna del contenedor.
  custom_ca_bundle = "${local.emulator_dir}/ca.pem"

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

# Recursos de ejemplo. Eliminalos o adaptalos a tus necesidades.
resource "aws_s3_bucket" "example" {
  bucket        = var.example_bucket_name
  force_destroy = true
}

resource "aws_s3_object" "example" {
  bucket       = aws_s3_bucket.example.id
  key          = "hola.txt"
  content      = "Hola desde AWS Emulator\n"
  content_type = "text/plain"
}

resource "aws_sqs_queue" "example" {
  name = var.example_queue_name
}
