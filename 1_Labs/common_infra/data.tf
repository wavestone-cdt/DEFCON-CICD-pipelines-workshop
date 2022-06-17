/*
======================================
Define specific data variable to grab the AWS account id
======================================
*/

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {}

data "aws_caller_identity" "src" {
	provider = aws.src
}

data "aws_caller_identity" "dest" {
	provider = aws.dest
}
