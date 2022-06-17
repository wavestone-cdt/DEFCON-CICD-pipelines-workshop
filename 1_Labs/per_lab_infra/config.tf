# To keep track of the index of the lab
#  may be used in conjuction with terraform.workspace
variable "lab_id" { type = number }

#Jump kali configuration, AMI on us-west-1
variable "jump_ami_instance" {default = "ami-0897a99f163fb6777"}
variable "jump_instance_type" { default = "t2.large" }
variable "jump_bash_script" { default = "jump_scripts/deploy.sh" }
variable "jump_ec2_volume_size" { default = 50 }

#Jenkins configuration, AMI on us-west-1
variable "jenkins_ami_instance" {default = "ami-03107083c20594f86"}
variable "jenkins_instance_type" { default = "t2.large" }
variable "jenkins_api_key" { default = "1180c7b52bcdd468a6aeae8b9c730ee305" }
variable "jenkins_bash_script" { default = "jenkins_scripts/add_secret.sh" }
#variable "jump_ec2_volume_size" { default = 50 }

#Gitlab configuration, AMI on us-west-1
variable "gitlab_ami_instance" {default = "ami-057c76cf638ee711a"}
variable "gitlab_instance_type" { default = "t2.large" }
variable "gitlab_bash_script" { default = "gitlab_scripts/init.sh" }
variable "gitlab_api_key" { default = "SYZ3Xt-tFfdHy6Gpd_xy" }

# DNS configuration
variable "dns_record_ttl" { default = "300" } # 5 minutes

# Load config from common_infra terraform output
data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    profile = "infra"
    bucket = "tfstatecicdw1212"
    key    = "tfstatecicdw1212/common_infra.tfstate"
    region  = "us-west-1"
  }
}
# ease access to the common variables
locals {
    # Global settings
    name      = data.terraform_remote_state.common.outputs.name
    region    = data.terraform_remote_state.common.outputs.region
    lab_count = data.terraform_remote_state.common.outputs.lab_count

    # SSH key settings
    ssh_key_id = data.terraform_remote_state.common.outputs.admin_ssh_key_id
    ssh_key_file = data.terraform_remote_state.common.outputs.admin_ssh_key_file
    ssh_key_priv_file = data.terraform_remote_state.common.outputs.admin_ssh_key_priv_file

    # Network settings
    dns_zone_id             = data.terraform_remote_state.common.outputs.dns_zone_id
    vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
    private_subnets         = data.terraform_remote_state.common.outputs.vpc_private_subnets
    public_subnets          = data.terraform_remote_state.common.outputs.vpc_public_subnets
    lab_subnet              = data.terraform_remote_state.common.outputs.vpc_lab_subnets[var.lab_id]
    jump_servers_net        = data.terraform_remote_state.common.outputs.jump_servers_net[var.lab_id]
    eks_cluster_net         = data.terraform_remote_state.common.outputs.eks_cluster_net[var.lab_id]
    eks_workers_net         = data.terraform_remote_state.common.outputs.eks_workers_net[var.lab_id]
    jump_servers_sec_grp_id = data.terraform_remote_state.common.outputs.jump_servers_security_group_id

    # IAM
    k8s_cluster_role_arn = data.terraform_remote_state.common.outputs.k8s_cluster_role_arn
    k8s_workers_role_arn = data.terraform_remote_state.common.outputs.k8s_workers_role_arn

    master_profile = data.terraform_remote_state.common.outputs.master_role
    master_bucket_id = data.terraform_remote_state.common.outputs.master_bucket_id

    # ApplicationDeployment-user = data.terraform_remote_state.common.outputs.ApplicationDeployment-user
    # ApplicationDeployment-user-secret = data.terraform_remote_state.common.outputs.ApplicationDeployment-user-secret

    ApplicationDeploymentPolicyArn      = data.terraform_remote_state.common.outputs.ApplicationDeploymentPolicy
    src_custom_iam_ro_src_iam_policyArn = data.terraform_remote_state.common.outputs.src_custom_iam_ro_src_iam_policy

    datapassword = csvdecode(file("jump_password.csv"))

    # ECR repo
    tomcat_repo_url = data.terraform_remote_state.common.outputs.tomcat_repo_url
    debian_repo_url = data.terraform_remote_state.common.outputs.debian_repo_url
    kali_repo_url   = data.terraform_remote_state.common.outputs.kali_repo_url
}

# EKS configuration
variable "eks_k8s_version" { default = "1.22" }
variable "eks_instance_type" { default = "t2.small" }
