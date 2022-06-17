# Global config
output "name" {
    description = "Name for resources"
    value       = var.name
}
output "region" {
    description = "AWS region for resources"
    value       = var.region
}
output "lab_count" {
    description = "Number of labs which may be created"
    value       = var.lab_count
}

# Size of lab networks
output "lab_network_length" {
    description = "Length of the lab networks: ensure they are large enough"
    value       = (
        parseint(split("/", var.cidr_block)[1], 10)  # length of the CIDR block
        + local.block_type_prefix_len
        + local.lab_prefix_len
        + local.subnet_prefix_len
    )
}

# SSH key
output "admin_ssh_key_id" {
    description = "ID of the admin SSH key"
    value = aws_key_pair.admin.id
}
output "admin_ssh_key_file" {
    description = "File of the public key of the admin SSH key"
    value = var.ssh_key
}
output "admin_ssh_key_priv_file" {
    description = "File of the private key of the admin SSH key"
    value = var.ssh_key_priv
}

# S3 common configuration and role

output "master_role" {
    description = "AWS role to access S3 bucket containing configuration file"
    value = aws_iam_instance_profile.master_profile.name
}

output "master_bucket_id" {
    description = "S3 bucket containing configuration file"
    value = aws_s3_bucket.jump_bucket.id
}

# Network data

output "dns_zone_id" {
    description = "ID of the DNS zone"
    value       = data.aws_route53_zone.lab_zone.zone_id
}
output "vpc_id" {
    description = "ID of the VPC"
    value       = module.vpc.vpc_id
}
output "vpc_lab_subnets" {
    description = "Lab subnets of the VPC"
    value       = local.lab_subnets
}
output "vpc_private_subnets" {
    description = "Private networks of the VPC"
    value       = module.vpc.private_subnets
}
output "vpc_public_subnets" {
    description = "Public networks of the VPC"
    value       = module.vpc.public_subnets
}
output "eks_cluster_net" {
    description = "Indexes of the subnets for eks clusters"
    value       = local.eks_cluster_net
}
output "eks_workers_net" {
    description = "Indexes of the subnets for eks workers"
    value       = local.eks_workers_net
}
output "jump_servers_security_group_id" {
    description = "ID of the security groups associated with jump servers"
    value       = aws_security_group.vpc_jump_servers.id
}
output "jump_servers_net" {
    description = "Indexes of the subnets for jump "
    value       = local.jump_servers_net
}

# ECR data
output "tomcat_repo_url" {
    description = "URL of the ECR repo for tomcat"
    value       = aws_ecr_repository.tomcat.repository_url
}
output "kali_repo_url" {
    description = "URL of the ECR repo for kali"
    value       = aws_ecr_repository.kali.repository_url
}
output "debian_repo_url" {
    description = "URL of the ECR repo for debian"
    value       = aws_ecr_repository.debian.repository_url
}

# EKS roles

output "k8s_cluster_role_arn" {
    description = "ARN of the role created for clusters"
    value       = module.k8s_iam.eks_role.arn
}
output "k8s_workers_role_arn" {
    description = "ARN of the role created for workers"
    value       = module.k8s_iam.workers_role.arn
}


# AWS Priv Esc

output "ApplicationDeploymentPolicy" {
    description = "ApplicationDeploymentPolicy arn"
    value       = aws_iam_policy.ApplicationDeploymentPolicy.arn
}

output "src_custom_iam_ro_src_iam_policy" {
    description = "src_custom_iam_ro_src_iam_policy arn"
    value       = aws_iam_policy.src_custom_iam_ro_src_iam_policy.arn
}
