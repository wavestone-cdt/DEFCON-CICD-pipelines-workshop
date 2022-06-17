/*
======================================
INFRA : Upload configuration file to S3, used the kali EC2 (RDP, VNC & co)
======================================
*/

resource "aws_s3_bucket" "jump_bucket" {
    bucket = lower("${var.name}-${var.region}")
}

resource "aws_s3_bucket_public_access_block" "jump_iam" {
    bucket = aws_s3_bucket.jump_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_object" "object" {
    for_each = fileset("./jump_config_files/", "**")
    bucket   = aws_s3_bucket.jump_bucket.id
    key      = each.value
    source   = "./jump_config_files/${each.value}"
    etag     = filemd5("./jump_config_files/${each.value}")
}


/*
======================================
DEST : Final "flag" stored in S3
======================================
*/

locals {
  flag = <<EOF
Congratulations, you found me! Hack the Planet and the Cloud!
EOF
}

resource "aws_s3_bucket" "dest_flag_bucket" {
  provider = aws.dest
  bucket   = "heylookatmemyfriends"
  acl      = "private"
  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket_object" "dest_flag_s3_object" {
  provider       = aws.dest
  bucket         = aws_s3_bucket.dest_flag_bucket.id
  key            = "Congratulations.txt"
  content_base64 = base64encode(local.flag)
}
