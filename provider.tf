provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "dev-bucket-for-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
