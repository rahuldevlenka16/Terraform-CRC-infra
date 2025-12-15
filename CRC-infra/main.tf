resource "aws_dynamodb_table" "visitor_count_table" {
    name         = var.table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"

    attribute {
        name = "id"
        type = "S"
    }

#   tags = {
#     Project = "CloudResume"
#   }
}


#--------------------------------lamda starts

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

#create policy
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
        Resource = aws_dynamodb_table.visitor_count_table.arn
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

#Attach the policy
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "visitor_lambda" {
  function_name = "visitor-counter" #lambda fucntion name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.lambda_handler" #file name must be index.py
  runtime       = "python3.11"

  filename         = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip") #it will update during any changes to the python file

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count_table.name #lambda function will fetch this value
    }
  }
}

#--------------------------------lamda ends


#--------------------------------api starts
#create HTTP api
resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "visitor-api"
  protocol_type = "HTTP"
}

#integrate it with lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.visitor_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_lambda.invoke_arn
}

# Create GET route
resource "aws_apigatewayv2_route" "count_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Create default stage with auto deploy
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default" # if you give dev, you will need to append dev/count/
  auto_deploy = true
}

#allow api to call lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}
#--------------------------------api ends
