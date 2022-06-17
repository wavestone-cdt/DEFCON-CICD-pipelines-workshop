# Create an ECR to be used by EKS
resource "aws_ecr_repository" "tomcat" {
  name                 = "tomcat"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
resource "aws_ecr_repository" "kali" {
  name                 = "kali"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
resource "aws_ecr_repository" "debian" {
  name                 = "debian"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
