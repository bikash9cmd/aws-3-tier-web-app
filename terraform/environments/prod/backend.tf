terraform {
  backend "s3" {
 
    bucket         = "bikash-terraform-state-
    key            = "prod/3-tier-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
