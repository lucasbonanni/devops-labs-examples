

# Recursos de ejemplo para la demo
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "mi-bucket-laboratorio-demo"
}

resource "aws_dynamodb_table" "demo_table" {
  name         = "TablaDemo"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}
