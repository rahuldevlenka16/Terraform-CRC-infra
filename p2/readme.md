📁 Folder (same project, new files added)

You can keep everything in the same directory for now:

cloud-resume-infra/
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── lambda/
    └── index.py

1️⃣ Create Lambda code (VERY SIMPLE)

Create file: lambda/index.py

import json
import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

def lambda_handler(event, context):
    response = table.update_item(
        Key={"id": "counter"},
        UpdateExpression="ADD #c :inc",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={":inc": 1},
        ReturnValues="UPDATED_NEW"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "count": int(response["Attributes"]["count"])
        })
    }


👉 This is exactly the logic you tested earlier using CLI.

2️⃣ Zip the Lambda code (manual for now)

From project root:

cd lambda
zip lambda.zip index.py
cd ..


You should now have:

lambda/lambda.zip

3️⃣ IAM Role for Lambda (Terraform)

Add to main.tf (below DynamoDB resource).

A. Lambda execution role
resource "aws_iam_role" "lambda_exec_role" {
  name = "visitor-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

B. IAM policy for DynamoDB + Logs
resource "aws_iam_policy" "lambda_policy" {
  name = "visitor-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitor_count.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

C. Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

4️⃣ Lambda function (Terraform)

Add this to main.tf:

resource "aws_lambda_function" "visitor_lambda" {
  function_name = "visitor-counter"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"

  filename         = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }
}

5️⃣ Apply Terraform
terraform plan
terraform apply


Type yes.

6️⃣ Verify Phase 2 using AWS CLI (IMPORTANT)
A. Invoke Lambda manually
aws lambda invoke \
  --function-name visitor-counter \
  response.json \
  --region ap-south-1

B. Check response
cat response.json


Expected output:

{"statusCode":200,"body":"{\"count\":1}"}


Run it again — count should increment.

C. Verify DynamoDB again
aws dynamodb get-item \
  --table-name visitor-count \
  --key '{"id":{"S":"counter"}}' \
  --region ap-south-1


Count should match Lambda invocations.

🧠 What you learned in Phase 2

IAM trust vs permission policies

How Lambda assumes a role

How env variables connect Lambda → DynamoDB

How to debug without API Gateway

Why least-privilege IAM matters

✅ Phase 2 completion checklist

 Lambda created via Terraform

 Lambda can update DynamoDB

 No permission errors

 Counter increments correctly