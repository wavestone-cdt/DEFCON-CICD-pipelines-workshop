################################################################################
# Cluster Data
################################################################################
variable "cluster_name" {
  description = "Name of associated EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Version of associated EKS cluster"
  type        = string
  default     = ""
}

################################################################################
# Cluster VPC Data
################################################################################
variable "cluster_vpc_id" {
  description = "ID where to create a subnet for the cluster"
  type        = string
}

variable "cluster_availability_zones_num" {
  description = "Number of availability zones the cluster should be exposed to"
  type        = number
  default     = 2
}

variable "cluster_subnet" {
  description = "CIDR block to assign to the subnet of the cluster"
  type        = string
}

variable "workers_subnet" {
  description = "CIDR block to assign to the subnet of the workers"
  type        = string
}

variable "subnets_base_name" {
  description = "Base name for the created subnets"
  type        = string
  default     = null
}

variable "endpoint_private_access" {
  description = "Whether to expose privately the Kubernetes API"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether to expose publicly the Kubernetes API"
  type        = bool
  default     = false
}

################################################################################
# IAM Data
################################################################################

variable "cluster_role_arn" {
  description = "ARN of the role of the associated EKS cluster"
  type        = string
}

variable "workers_role_arn" {
  description = "ARN of the role of the associated worker nodes"
  type        = string
}

################################################################################
# Node group Data
################################################################################

variable "workers_instance_type" {
  description = "Instance type of EC2 for the worker nodes"
  type        = string
}

