
terraform {

  backend "s3" {
    encrypt        = true
    bucket         = "bw5mnukhqqvdw7du-terraform-state-bucket"
    key            = "devops-challenge/terraform.tfstate"
    dynamodb_table = "bw5mnukhqqvdw7du-terraform-state-lock-table"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "envs" {
  source = "./envs"
}
