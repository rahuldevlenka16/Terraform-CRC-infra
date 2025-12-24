# Serverless Cloud Resume Infrastructure (AWS + Terraform)

This project is a **production-style serverless web application** built on **AWS using Terraform**, inspired by the **Cloud Resume Challenge**.  
The goal was not only to implement the challenge, but to **design, validate, and harden the infrastructure step by step**, following real-world DevOps practices.

---

## Repository structure info:

**CRC-infra** folder contains the main terraform files with sample index.html to upload in s3 and lambda function to increment the visit counter in dynamodb.

**p1-p7** folders contains documentation of phases from phase 1 to phase 7 while building the project, more details are explained below.


## 🧱 Architecture Overview

- **Frontend**: Static website hosted on Amazon S3  
- **CDN & HTTPS**: Amazon CloudFront  
- **Backend**: API Gateway → AWS Lambda → DynamoDB  
- **Infrastructure as Code**: Terraform  
- **Security**: Private S3 bucket with CloudFront Origin Access Control (OAC)  
- **Scalability**: Fully serverless, auto-scaling, pay-per-use  

---

## 📌 Phase-by-Phase Implementation

### Phase 1: DynamoDB (Data Layer)
- Created a DynamoDB table using on-demand billing (`PAY_PER_REQUEST`)
- Designed the table to support **atomic updates** to safely handle concurrent visitor updates

---

### Phase 2: IAM + Lambda (Compute Layer)
- Created an IAM role with least-privilege permissions
- Built a Lambda function to increment and return the visitor count
- Verified Lambda functionality using AWS CLI before public exposure

---

### Phase 3: API Gateway (HTTP Access)
- Created an API Gateway **HTTP API**
- Integrated API Gateway with Lambda using proxy integration
- Added a `GET /count` endpoint
- Configured CORS at the API Gateway level to support browser-based requests

---

### Phase 4: S3 Static Website Hosting (Frontend)
- Created an S3 bucket for static website hosting
- Uploaded a basic `index.html` to validate frontend hosting
- Verified access using the S3 website endpoint

---

### Phase 5: CloudFront (CDN + HTTPS)
- Added CloudFront in front of S3 to enable HTTPS
- Configured HTTP → HTTPS redirection
- Enabled caching for static content
- Verified access using the CloudFront domain

---

### Phase 6: Custom Domain (Skipped)
- Custom domain integration using Route 53 and ACM was intentionally skipped
- Architecture supports adding this later without changes

---

### Phase 7: Security Hardening (Production-Grade)
- Disabled S3 static website hosting
- Blocked all public access to the S3 bucket
- Switched CloudFront origin to S3 REST endpoint
- Implemented **CloudFront Origin Access Control (OAC)**
- Updated S3 bucket policy to allow access **only from CloudFront**
- Verified that direct S3 access is blocked while CloudFront access works

---

## 🔄 Frontend–Backend Flow

1. User accesses the site via CloudFront (HTTPS)
2. Static content is served from the private S3 bucket
3. Frontend JavaScript calls API Gateway (`GET /count`)
4. API Gateway invokes Lambda
5. Lambda atomically updates the visitor count in DynamoDB
6. Updated count is returned and displayed in the browser

---

## 🔐 Security Considerations

- S3 bucket is fully private and not directly accessible
- CloudFront is the only entry point to static content
- API Gateway CORS is restricted to the CloudFront domain
- IAM roles follow least-privilege principles

---

## 🧠 Key Learnings

- Proper separation of infrastructure provisioning and application deployment
- Secure CloudFront-to-S3 access using Origin Access Control
- Correct CORS handling at the API Gateway level and lambda level
- Incremental infrastructure validation using Terraform
- Serverless architecture design for scalability and cost efficiency

---

## 💰 Cost Considerations

All services fall within AWS Free Tier or incur negligible cost for low traffic:
- AWS Lambda
- DynamoDB (on-demand)
- API Gateway (HTTP API)
- S3 and CloudFront

---

## 📈 Future Enhancements

- Custom domain using Route 53 and ACM
- CI/CD pipelines using GitHub Actions(completed)
- CloudFront cache invalidation automation (completed)
- CloudWatch logging and monitoring
- AWS WAF integration

---

## 📚 References

- [Cloud Resume Challenge](https://cloudresumechallenge.dev/)
- AWS Documentation
- Terraform Documentation


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
