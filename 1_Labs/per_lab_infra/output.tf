output "lab_count" {
    description = "Number of labs which may be created"
    value       = local.lab_count
}
# EKS cluster name
output "eks_cluster_name" {
    description = "EKS cluster name"
    value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
    description = "EKS cluster endpoint"
    value       = module.eks.cluster_endpoint
}

# EC2 jump per leb

output "kali_ips" {
    description = "IP addresses assigned to the jump kali"
    value       = aws_instance.jump_kali.public_ip
}

output "gitlab_ip" {
    description = "IP addresses assigned to the jump kali"
    value       = aws_instance.gitlab.private_ip
}

output "jenkins_ip" {
    description = "IP addresses assigned to the jump kali"
    value       = aws_instance.jenkins.private_ip
}

# User unprivileged per lab

output "ApplicationDeployment-name" {
    description = "user_perlab name"
    value       = aws_iam_user.user_perlab.name
}

output "user_perlab" {
    description = "user_perlab account ID"
    value       = aws_iam_access_key.user_perlab_key.id
}

output "user_perlab_key" {
    sensitive = true
    description = "user_perlab_key secret"
    value       = aws_iam_access_key.user_perlab_key.secret
}

output "ApplicationDeployment_user_real" {
    description = "ApplicationDeployment_user name"
    value       = aws_iam_user.ApplicationDeployment_user.name
}

output "ApplicationDeployment_user" {
    description = "ApplicationDeployment account ID"
    value       = aws_iam_access_key.ApplicationDeployment_user_key.id
}

output "ApplicationDeployment_user_key" {
    sensitive = true
    description = "ApplicationDeployment secret"
    value       = aws_iam_access_key.ApplicationDeployment_user_key.secret
}


# Per lab kubernetes user
output "jenkins_user_access_id" {

    description = "Access ID of the jenkins user"
    value       = aws_iam_access_key.jenkins.id
}
output "jenkins_user_access_secret" {
    description = "Access secret of the jenkins user"
    value       = aws_iam_access_key.jenkins.secret
    sensitive   = true
}
output "monitoring_user_access_id" {

    description = "Access ID of the monitoring user"
    value       = aws_iam_access_key.k8s_monitoring.id
}
output "monitoring_user_access_secret" {
    description = "Access secret of the monitoring user"
    value       = aws_iam_access_key.k8s_monitoring.secret
    sensitive   = true
}
