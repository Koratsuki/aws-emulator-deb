output "bucket_name" {
  description = "Nombre del bucket S3 de ejemplo."
  value       = aws_s3_bucket.example.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3 de ejemplo."
  value       = aws_s3_bucket.example.arn
}
