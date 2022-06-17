// --------------- Default --------------

provider "aws" {
    region  = local.region
    profile = "infra"
}


// --------------- DNS --------------
// temporary profile until DNS zone is transfer to infra
provider "aws" {
    alias   = "dns"
    region  = local.region
    profile = "dns"
}


// --------------- AWS Priv Esc --------------
provider "aws" {
    alias   = "src"
    region  = local.region
    profile = "src"
}

// --------------- AWS Lateral Movement --------------

provider "aws" {
    alias   = "dest"
    region  = local.region
    profile = "dest"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--profile", "infra", "--cluster-name", module.eks.cluster_id]
  }
}
