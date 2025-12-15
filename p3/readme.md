Great 👍
Let’s move forward to **Phase 3: API Gateway (Expose Lambda via HTTP)** — this is where your backend becomes a **real API**.

We’ll still keep it **small, testable, and non-overwhelming**.

---

# 🔹 Phase 3: API Gateway → Lambda (HTTP API)

### Goal of this phase

> Expose your Lambda function using **API Gateway (HTTP API)** and verify it using `curl`.

After this phase, you’ll have:

```
https://<api-id>.execute-api.<region>.amazonaws.com/count
```

---

## ✅ What we will build in this phase

* API Gateway (HTTP API)
* Lambda integration
* Route: `GET /count`
* Permission for API Gateway to invoke Lambda

---

## 1️⃣ Create API Gateway (Terraform)

Add this to **main.tf**:

```hcl
resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "visitor-api"
  protocol_type = "HTTP"
}
```

---

## 2️⃣ Create Lambda integration

```hcl
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.visitor_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.visitor_lambda.invoke_arn
}
```

---

## 3️⃣ Create route (`GET /count`)

```hcl
resource "aws_apigatewayv2_route" "count_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
```

---

## 4️⃣ Create default stage (auto-deploy)

```hcl
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default"
  auto_deploy = true
}
```

---

## 5️⃣ Allow API Gateway to invoke Lambda (VERY IMPORTANT)

Without this, you’ll get **403 / 500 errors**.

```hcl
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}
```

---

## 6️⃣ Output the API URL

Add to **outputs.tf**:

```hcl
output "api_url" {
  value = aws_apigatewayv2_api.visitor_api.api_endpoint
}
```

---

## 7️⃣ Apply Terraform

```bash
terraform plan
terraform apply
```

---

## 8️⃣ Test Phase 3 using curl (CRITICAL)

### A. Get API URL

Terraform will output something like:

```
https://abc123.execute-api.ap-south-1.amazonaws.com
```

### B. Call the endpoint

Note: if you used any other stage name like dev, you need to use api_url/dev/count

```bash
curl https://<api-id>.execute-api.ap-south-1.amazonaws.com/count
```

Expected response:

```json
{"count": 2}
```

Run it again → count increments.

---

## 🧠 If something goes wrong (quick debug)

### ❌ `{"message":"Not Found"}`

* You forgot `/count`
* Or route key is wrong

### ❌ `403 Forbidden`

* Lambda permission missing
* Re-check `aws_lambda_permission`

### ❌ `502 / 504`

* Lambda error
* Test Lambda directly via CLI again

---

## ✅ Phase 3 completion checklist

* [x] API Gateway created
* [x] `/count` route works
* [x] Lambda invoked via HTTP
* [x] Counter increments

---