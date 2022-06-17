terraform {
 backend "s3" {
   bucket = "tfstatecicdw1212"
   key    = "tfstatecicdw1212/common_infra.tfstate"
   region = "us-west-1"
   profile = "infra"

   skip_credentials_validation = true
 }
}
