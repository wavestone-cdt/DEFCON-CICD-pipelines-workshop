
/*
======================================
EC2 with a Kali to give lab access
======================================
*/

data "template_file" "init" {
    template = file(var.jump_bash_script)

    vars = {
        region                = local.region
        bucket                = local.master_bucket_id
        gitlab_ip             = aws_instance.gitlab.private_ip
        jenkins_ip            = aws_instance.jenkins.private_ip
        lab_id                = var.lab_id
        lab_name              = terraform.workspace
        app_id                = aws_iam_access_key.ApplicationDeployment_user_key.id
        app_secret            = aws_iam_access_key.ApplicationDeployment_user_key.secret
        k8s_cluster           = module.eks.cluster_id
        lab_cidr              = local.lab_subnet
        k8s_jenkins_id        = aws_iam_access_key.jenkins.id
        k8s_jenkins_secret    = aws_iam_access_key.jenkins.secret
        k8s_monitoring_id     = aws_iam_access_key.k8s_monitoring.id
        k8s_monitoring_secret = aws_iam_access_key.k8s_monitoring.secret
        kali_repo_url         = local.kali_repo_url
        password              = local.datapassword[var.lab_id].password
    }
}

data "template_file" "add_secret_to_jenkins" {
    template = file(var.jenkins_bash_script)

    vars = {
        gitlab_ip                  = aws_instance.gitlab.private_ip
        ApplicationDeployment_name = aws_iam_user.user_perlab.name
        jenkins_api_key            = var.jenkins_api_key
        k8s_user                   = aws_iam_access_key.jenkins.id
        k8s_secret                 = aws_iam_access_key.jenkins.secret
        k8s_cluster                = module.eks.cluster_id
        lab_id                     = lower(terraform.workspace)
    }
}
data "template_file" "init_gitlab" {
    template = file(var.gitlab_bash_script)

    vars = {
        gitlab_api_key = var.gitlab_api_key
        lab_id         = lower(terraform.workspace)
        job            = "{job}"
    }
}

resource "aws_instance" "jump_kali" {

    ami                  = var.jump_ami_instance
    instance_type        = var.jump_instance_type
    key_name             = local.ssh_key_id
    iam_instance_profile = local.master_profile

    # use the subnet dedicated to the current lab

    subnet_id              = local.public_subnets[local.jump_servers_net]
    vpc_security_group_ids = [local.jump_servers_sec_grp_id]

    root_block_device {
        volume_size = var.jump_ec2_volume_size
    }

    tags = {
        Name      = "${local.name}_${ terraform.workspace }_kali"
    }

    user_data = data.template_file.init.rendered
}


/*
======================================
EC2 with a Gitlab
======================================
*/

resource "aws_instance" "gitlab" {

    ami           = var.gitlab_ami_instance
    instance_type = var.gitlab_instance_type
    key_name      = local.ssh_key_id
    iam_instance_profile   = local.master_profile

    # use the subnet dedicated to the current lab

    subnet_id              = local.public_subnets[local.jump_servers_net]
    vpc_security_group_ids = [local.jump_servers_sec_grp_id]

    /*root_block_device {
        volume_size = var.jump_ec2_volume_size
    }*/

    tags = {
        Name      = "${local.name}_${ terraform.workspace }_gitlab"
    }

    user_data = data.template_file.init_gitlab.rendered

}

/*
======================================
EC2 with a Jenkins
======================================
*/

resource "aws_instance" "jenkins" {

    ami           = var.jenkins_ami_instance
    instance_type = var.jenkins_instance_type
    key_name      = local.ssh_key_id
    iam_instance_profile   = local.master_profile

    # use the subnet dedicated to the current lab

    subnet_id              = local.public_subnets[local.jump_servers_net]
    vpc_security_group_ids = [local.jump_servers_sec_grp_id]

    /*root_block_device {
        volume_size = var.jump_ec2_volume_size
    }*/

    tags = {
        Name      = "${local.name}_${ terraform.workspace }_jenkins"
    }

    connection {
        type     = "ssh"
        user     = "bitnami"
        host     = self.public_ip
        private_key = file(local.ssh_key_priv_file)
    }

    user_data = data.template_file.add_secret_to_jenkins.rendered
}
