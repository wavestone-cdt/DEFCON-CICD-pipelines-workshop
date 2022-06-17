resource "aws_s3_bucket" "remote_state_s3_bucket" {
  bucket = "tfstatecicdw1212"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    transition {
      storage_class = "STANDARD_IA"
      days          = 30
    }
  }
}
