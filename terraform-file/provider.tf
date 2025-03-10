provider "aws" {
  region = "us-east-1"
  max_retries              = 5  
  skip_credentials_validation = true  
  skip_metadata_api_check = true 
}