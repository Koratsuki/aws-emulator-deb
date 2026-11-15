variable "region" {
  description = "Region de AWS que usa el provider."
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "Perfil de uso en el emulador."
  type        = string
  default     = "default"
}

variable "endpoint_url" {
  description = "URL base del emulador local de AWS."
  type        = string
  default     = "https://127.0.0.1:9297"
}

variable "example_bucket_name" {
  description = "Nombre del bucket S3 que crea el recurso de ejemplo."
  type        = string
  default     = "emulator-terraform-example"
}

variable "example_queue_name" {
  description = "Nombre de la cola SQS que crea el recurso de ejemplo."
  type        = string
  default     = "emulator-terraform-example"
}
