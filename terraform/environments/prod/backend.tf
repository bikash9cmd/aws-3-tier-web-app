terraform {
  backend "s3" {
    # Replace <YOUR_ACCOUNT_ID> with your actual AWS account ID
    # Run scripts/bootstrap-state.sh first to create this bucket
    bucket         = "bikash-terraform-state-<YOUR_ACCOUNT_ID>"
    key            = "prod/3-tier-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
