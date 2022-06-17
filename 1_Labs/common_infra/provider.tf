// --------------- Default --------------

provider "aws" {
    region  = var.region
    profile = "infra"
}


// --------------- DNS --------------
// temporary profile until DNS zone is transfer to infra
provider "aws" {
    alias   = "dns"
    region  = var.region
    profile = "dns"
}


// --------------- AWS Priv Esc --------------
provider "aws" {
    alias   = "src"
    region  = var.region
    profile = "src"
}

// --------------- AWS Lateral Movement --------------

provider "aws" {
    alias   = "dest"
    region  = var.region
    profile = "dest"
}
