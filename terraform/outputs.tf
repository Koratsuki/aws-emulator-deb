output "bucket_name" {
  description = "Nombre del bucket S3 de ejemplo."
  value       = aws_s3_bucket.example.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3 de ejemplo."
  value       = aws_s3_bucket.example.arn
}

output "object_key" {
  description = "Clave del objeto S3 de ejemplo."
  value       = aws_s3_object.example.key
}

output "queue_url" {
  description = "URL de la cola SQS de ejemplo."
  value       = aws_sqs_queue.example.url
}
