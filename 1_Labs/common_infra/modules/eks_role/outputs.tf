################################################################################
# IAM Roles
################################################################################

output "eks_role" {
  description = "IAM role for an EKS cluster"
  value       = {
    name      = aws_iam_role.eks_role.name
    arn       = aws_iam_role.eks_role.arn
    unique_id = aws_iam_role.eks_role.unique_id
    attachments = [
      aws_iam_role_policy_attachment.eks_role-AmazonEKSVPCResourceController,
    ]
  }
}

output "workers_role" {
  description = "IAM role for a worker node"
  value       = {
    name      = aws_iam_role.workers_role.name
    arn       = aws_iam_role.workers_role.arn
    unique_id = aws_iam_role.workers_role.unique_id
    attachments = [
      aws_iam_role_policy_attachment.workers_role-AmazonEKSWorkerNodePolicy,
      aws_iam_role_policy_attachment.workers_role-AmazonEKS_CNI_Policy,
      aws_iam_role_policy_attachment.workers_role-AmazonEC2ContainerRegistryReadOnly,
    ]
  }
}
