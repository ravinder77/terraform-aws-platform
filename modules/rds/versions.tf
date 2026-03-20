terraform {

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}