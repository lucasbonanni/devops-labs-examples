output "bucket_arn" {
  value = aws_s3_bucket.demo_bucket.arn
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.demo_table.arn
}
