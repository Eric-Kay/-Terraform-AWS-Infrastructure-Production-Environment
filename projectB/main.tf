provider "aws" {
	region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket11212025new"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}


module "vpc_prod" {
  source               = "../modules/aws-network"
  env                  = "prod"
  vpc_cidr             = "10.200.0.0/16"
  public_subnet_cidr  = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  private_subnet_cidr = ["10.200.11.0/24", "10.200.22.0/24", "10.200.33.0/24"]
  tags = {
    Owner   = "eric_devops"
    Code    = "777766"
    Project = "SuperPreject"
  }
}


module "stand-alone-server"{
	source = "../modules/aws-testserver"
	name = "eric_devops"
	subnet_id = module.vpc_prod.public_subnets_id[2]
}