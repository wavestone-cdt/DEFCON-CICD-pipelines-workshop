################################################################################
# EKS Role Data
################################################################################
variable "eks_role_name" {
  description = "Name of role for EKS cluster to create"
  type        = string
  default     = ""
}

variable "use_security_group_for_pod" {
  description = "Whether to enable security groups for pod"
  type        = bool
  default     = false
}

################################################################################
# Worker Nodes Role Data
################################################################################
variable "workers_role_name" {
  description = "Name of role for worker nodes to create"
  type        = string
  default     = ""
}

