Problems:



1. when I deploy the index.html and used js to fetch to count using the api url, it gave CORS error in the browser
"""
    index.html:1 Access to fetch at 'https://740yr3fo44.execute-api.ap-south-1.amazonaws.com/count' from origin 'https://cloud-resume-terraform-16-12-2025.s3.ap-south-1.amazonaws.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
    """"

    This happended as I did not allow CORS headerds in API gateway

    Fix:

    add the below response header in lambda function

        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({"count": count})

    then add in api gateway in terraform code also

        resource "aws_apigatewayv2_api" "visitor_api" {
        name          = "visitor-api"
        protocol_type = "HTTP"

        cors_configuration {
            allow_origins = ["*"]
            allow_methods = ["GET", "OPTIONS"]
            allow_headers = ["*"]
        }
        }

Note :

    If you want only cloudfront to access the API not any other website then use 

    in apiGW,
    cors_configuration {
        allow_origins = [
            "https://d3abcxyz.cloudfront.net"
        ]
        allow_methods = ["GET", "OPTIONS"]
        allow_headers = ["content-type"]
        }

    in lambda,
        return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "https://d3abcxyz.cloudfront.net",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "content-type"
        },
        "body": json.dumps({"count": count})
}





2. Terraform cannot and shoud not create the s3 and dynamodb backend to store s3 state and lock.

    THe problem is if you ask terraform to create s3 backend and also store the s3 backend in the main.tf like this below,

    terraform {
        backend "s3" {
            bucket = "tf-state"
        }
        }

        resource "aws_s3_bucket" "tf_state" {
        bucket = "tf-state"
    }

    it will create a paradox, " I need to store the state in tf-state bucket, but also I need to create tf_state bucket"

    When creating tf_state bucket, it need to store the state of this created bucket in state file, state file must be stored in the tf_state bucket itself, which is not yet created.


    So always create s3 bucket and dynamo db manually, before storing state.

    Best practice:

    1. create s3 and dynamodb manually
        aws s3api create-bucket \
        --bucket rahul-terraform-state-bucket-16-12-2025 \
        --region ap-south-1

        aws s3api put-bucket-versioning \
        --bucket rahul-terraform-state-bucket-16-12-2025 \
        --versioning-configuration Status=Enabled

        aws dynamodb create-table \
        --table-name terraform-locks \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST


    2. add the backend in main.tf
        ```
        terraform {
        backend "s3" {
            bucket         = "rahul-terraform-state-bucket-16-12-2025"
            key            = "cloud-resume/terraform.tfstate"
            region         = "ap-south-1"
            dynamodb_table = "terraform-locks"
            encrypt        = true
        }
        }
        ```
    3. terraform init -migrate-state
