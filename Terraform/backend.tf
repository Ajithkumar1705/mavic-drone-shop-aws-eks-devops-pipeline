terraform {
  backend "s3" {
    bucket         = "mavic-drone-shop-tfstate-ajithkumar1705" # from bootstrap output: state_bucket_name
    key            = "eks/terraform.tfstate"                   # path *within* the bucket for this project's state
    region         = "ap-south-1"                              # from bootstrap output: aws_region
    dynamodb_table = "mavic-drone-shop-tf-lock"                # from bootstrap output: lock_table_name
    encrypt        = true
  }
}
