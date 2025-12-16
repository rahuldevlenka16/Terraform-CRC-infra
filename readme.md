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





2. 
