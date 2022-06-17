# AWS global
variable "name" { default = "CICDEldorado" }
variable "region" { default = "us-west-1" }

# Lab count
locals {
    # the maximum number of labs which can be deployed
    max_lab_count = 90  # if changed change it also in lab_count validation
}
variable "lab_count" {
    description = "Number of lab to be created"
    type        = number
    default     = 1

    validation {
        condition     = var.lab_count > 0 && var.lab_count <= 90  # if changed change it also in max_lab_count validation
        error_message = "The lab count must be between 1 and 90"
    }
}


# Local ssh key to lab deployement
variable "ssh_key"  { default = "../ssh-keys/id_rsa.pub" }
variable "ssh_key_priv"  { default = "../ssh-keys/id_rsa" }

# Priv Esc variable
variable "src_lambda_to_admin_master_role_name" {default = "moniroting_all_role"}
variable "dest_admin_role_name" {default = "superadmin_role"}
variable "dest_iam_ro_role_name" {default = "readonly_role"}

# DNS definition
variable "dns_zone_name" { default = "devsecoops.academy." }

# Network configuration
# VPC network
variable "cidr_block" {default = "10.0.0.0/16"}
variable "subnets" {
    description = "All subnets to be created for each lab, and whether they are public/private and they use"
    default     = [
        # Attributes:
        #   public (bool): whether the subnet is public (ie exposed to internet)
        #   usage (string): a name/usage to be filtered after
        {public = true, usage="jump_servers"},
        {public = false, usage="eks_cluster"},
        {public = false, usage="eks_cluster"},
        {public = false, usage="eks_workers"},
        {public = false, usage="eks_workers"},
    ]
}
locals {
    # Block splitting method
    #   cidr_block_prefix   common/lab   lab index   per-lab subnet      subnet IPs
    # |-------------------|------------|-----------|-------------------|------------|
    #        16 bits          1 bits    depends on  depends on per-lab
    #                                   lab count   subnet count
    #
    # precompute some prefix length
    block_type_prefix_len = 1   # length of the prefix to differentiate lab/common
    lab_prefix_len  = ceil(log(local.max_lab_count, 2))
    subnet_prefix_len  = ceil(log(length(var.subnets), 2))
    common_block_prefix_len = 7   # length of the sub prefix within the common block

    # Create a CIDR block for labs & for common services
    common_cidr_block = cidrsubnet(var.cidr_block, local.block_type_prefix_len, 0)
    lab_cidr_block = cidrsubnet(var.cidr_block, local.block_type_prefix_len, 1)

    # create a set of subnet for each lab
    lab_subnets = [for i in range(local.max_lab_count): cidrsubnet(local.lab_cidr_block, local.lab_prefix_len, i)]

    # transform lab subnets variable into a list of public & private subnets
    all_lab_subnets     = [for cidr in local.lab_subnets: [for i, v in var.subnets: cidrsubnet(cidr, local.subnet_prefix_len, i)]]
    public_lab_subnets  = [for j, c in local.lab_subnets: [for i, v in var.subnets: local.all_lab_subnets[j][i] if v.public]]
    private_lab_subnets = [for j, c in local.lab_subnets: [for i, v in var.subnets: local.all_lab_subnets[j][i] if !v.public]]

    # flatten all networks for the VPC creation
    public_subnets  = concat(
        # common public subnets
        [
            cidrsubnet(local.common_cidr_block, local.common_block_prefix_len, local.common_public_net), # this one needs to be first to receive the NAT gateway for private networks
        ],
        # lab public subnets
        flatten(local.public_lab_subnets)
    )
    private_subnets = concat(
        # common private subnets
        [
            cidrsubnet(local.common_cidr_block, local.common_block_prefix_len, local.common_gitlab_net),
        ],
        # lab private subnets
        flatten(local.private_lab_subnets)
    )

    # indexes for the common block
    common_public_net = 1
    common_gitlab_net = 2

    # compute the index associated with the subnet of each usage
    jump_servers_net = [for j, c in local.lab_subnets: one([for i, v in var.subnets: index(local.public_subnets,  local.all_lab_subnets[j][i]) if v.usage == "jump_servers"])]
    eks_cluster_net  = [for j, c in local.lab_subnets:     [for i, v in var.subnets: index(local.private_subnets, local.all_lab_subnets[j][i]) if v.usage == "eks_cluster" ] ]
    eks_workers_net  = [for j, c in local.lab_subnets:     [for i, v in var.subnets: index(local.private_subnets, local.all_lab_subnets[j][i]) if v.usage == "eks_workers" ] ]
}
