################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.k8s.arn
}

#output "cluster_certificate_authority_data" {
#  description = "Base64 encoded certificate data required to communicate with the cluster"
#  value       = aws_eks_cluster.k8s.certificate_authority.data
#}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.k8s.endpoint
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = aws_eks_cluster.k8s.id
}

#output "cluster_oidc_issuer_url" {
#  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
#  value       = aws_eks_cluster.k8s.identity.oidc.issuer
#}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.k8s.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.k8s.status
}


################################################################################
# Worker Node Group
################################################################################

output "workers_arn" {
  description = "The Amazon Resource Name (ARN) of the workers' group"
  value       = aws_eks_node_group.k8s_workers_group.arn
}

output "workers_id" {
  description = "The name/id of the workers' group. Will block on cluster creation until the cluster is really ready"
  value       = aws_eks_node_group.k8s_workers_group.id
}

output "workers_status" {
  description = "Status of the workers' group. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_node_group.k8s_workers_group.status
}
