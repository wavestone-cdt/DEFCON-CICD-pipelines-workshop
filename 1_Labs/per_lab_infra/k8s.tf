# Create all clusters
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${ local.name }-${ terraform.workspace }-EKS-Clt"
  cluster_version = var.eks_k8s_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = local.vpc_id
  subnet_ids = [for idx in local.eks_cluster_net: local.private_subnets[idx]]

  # do not create IAM roles (already created elsewhere)
  create_iam_role = false
  iam_role_arn    = local.k8s_cluster_role_arn

  # aws-auth configmap
  manage_aws_auth_configmap = true

  # map IAM users to cluster roles
  aws_auth_users = [
    {
      userarn  = aws_iam_user.jenkins.arn
      username = aws_iam_user.jenkins.name
      groups   = ["jenkins"]
    },
    # explicitly authorize the caller identity
    {
      userarn  = aws_iam_user.k8s_monitoring.arn
      username = aws_iam_user.k8s_monitoring.name
      groups   = []
    },
  ]

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_self_all = {
      description    = "Master node to node all ports/protocols"
      protocol       = "-1"
      from_port      = 0
      to_port        = 0
      type           = "ingress"
      self           = true
    }
    egress_self_all = {
      description   = "Master node to node all egress ports/protocols"
      protocol      = "-1"
      from_port     = 0
      to_port       = 0
      type          = "egress"
      self          = true
    }
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
    ingress_api_from_jump_servers = {
      description                 = "From jump servers 443"
      protocol                    = "tcp"
      from_port                   = 443
      to_port                     = 443
      type                        = "ingress"
      source_security_group_id    = local.jump_servers_sec_grp_id
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress_http_from_all = {
      description         = "HTTP 80"
      protocol            = "tcp"
      from_port           = 80
      to_port             = 80
      type                = "ingress"
      cidr_blocks         = ["0.0.0.0/0"]
    }
    ingress_https_from_al = {
      description         = "HTTPS 443"
      protocol            = "tcp"
      from_port           = 443
      to_port             = 443
      type                = "ingress"
      cidr_blocks         = ["0.0.0.0/0"]
    }
    ingress_node_ports_from_all = {
      description               = "Node ports 30000-32767"
      protocol                  = "tcp"
      from_port                 = 30000
      to_port                   = 32767
      type                      = "ingress"
      cidr_blocks               = ["0.0.0.0/0"]
    }
  }

  eks_managed_node_group_defaults = {
    instance_types = [var.eks_instance_type]

    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    create_launch_template = false
    launch_template_name   = ""
  }

  eks_managed_node_groups = {
    linux_worker_group = {
      name            = "${ local.name }-${ terraform.workspace }-EKS-wks"

      # Group size
      min_size     = 1
      max_size     = 2
      desired_size = 1

      # network config
      subnet_ids = [for idx in local.eks_workers_net: local.private_subnets[idx]]

      # do not create IAM roles (already created elsewhere)
      create_iam_role = false
      iam_role_arn    = local.k8s_workers_role_arn

      # Add credentials to pivot to a privileged namespace
      create_launch_template          = true
      launch_template_use_name_prefix = true
      pre_bootstrap_user_data         = <<-EOT
      export MONITORING_ACCESS_KEY_ID="${ aws_iam_access_key.k8s_monitoring.id }"
      export MONITORING_SECRET_ACCESS_KEY="${ aws_iam_access_key.k8s_monitoring.secret }"
      EOT
      # to add additional args to kubelets
      #bootstrap_extra_args = "--kubelet-extra-args '--max-pods=110'"
    }
  }
}
