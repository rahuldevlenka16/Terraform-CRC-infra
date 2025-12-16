Excellent choice. **Phase 7 is real production hardening** — this matters more than a custom domain.

We’ll do this **carefully and incrementally**, without breaking your site.

---

# 🔹 Phase 7: Security Hardening (Make S3 Private, CloudFront-Only Access)

### Goal of this phase

> **Prevent direct public access to S3** and allow access **only through CloudFront**.

After this phase:

* ❌ S3 website URL → **blocked**
* ✅ CloudFront URL → **still works**
* ✅ Architecture becomes production-grade

---

## ⚠️ Important concept (read this once)

There are **two ways** CloudFront can access S3:

1. **OAI (Origin Access Identity)** – older
2. **OAC (Origin Access Control)** – newer (recommended)

👉 We’ll use **OAC** (modern, secure, recommended).

---

## 🔁 What will change from Phase 5

| Component          | Before              | After            |
| ------------------ | ------------------- | ---------------- |
| S3 bucket          | Public              | Private          |
| S3 website hosting | Enabled             | ❌ Disabled       |
| CloudFront origin  | S3 website endpoint | S3 REST endpoint |
| Access control     | Public policy       | CloudFront-only  |

This change is **intentional and correct**.

---

## 🧩 Step-by-step implementation

### 1️⃣ Remove S3 website hosting (important)

In **main.tf**, **delete or comment out**:

```hcl
resource "aws_s3_bucket_website_configuration" "website" { ... }
```

Why?

* CloudFront + OAC **cannot** use S3 website endpoints
* Only S3 REST endpoints are supported

---

### 2️⃣ Block public access on S3

Update / add:

```hcl
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

This **fully blocks public access**.

---

### 3️⃣ Remove public bucket policy

Delete this resource:

```hcl
aws_s3_bucket_policy.public_read
```

Public access must be **completely removed**.

---

### 4️⃣ Create CloudFront Origin Access Control (OAC)

Add to **main.tf**:

```hcl
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "cloud-resume-oac"
  description                       = "OAC for Cloud Resume S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

---

### 5️⃣ Update CloudFront origin to use S3 REST endpoint

Replace your **CloudFront origin block** with this:

```hcl
origin {
  domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
  origin_id   = "s3-origin"

  origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
}
```

Also change the previous name in default_cache_behavior attribute,
```hcl
target_origin_id       = "s3-origin"
```

❌ Remove `custom_origin_config`
❌ Remove website endpoint usage

---

### 6️⃣ Update default root object (still needed)

Keep this in CloudFront:

```hcl
default_root_object = "index.html"
```

---

### 7️⃣ Allow CloudFront to read from S3 (bucket policy)

Add this **new bucket policy**:

```hcl
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "AllowCloudFrontAccess",
			"Effect": "Allow",
			"Principal": {
				"Service" : "cloudfront.amazonaws.com"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::cloud-resume-terraform-16-12-2025/*",
			"Condition": {
				"StringEquals": {
					"aws:SourceArn": "aws_cloudfront_distribution.cdn.arn"
				}
			}
		}
	]
})
}
```
Add this to outupt 
```
output "s3_url" {
value = aws_s3_bucket.frontend_bucket.bucket_domain_name
}
```
comment out the website output


This is the **core security rule**.

---

## 🚀 Apply changes

```bash
terraform plan
terraform apply
```

⏳ CloudFront may take **5–10 minutes** to redeploy.

---

## ✅ Test Phase 7 (CRITICAL)

### 1️⃣ Test CloudFront URL

```text
https://<your-cloudfront-id>.cloudfront.net
```

✅ Should load normally

---

### 2️⃣ Test S3 direct access (must FAIL)

Try:

```text
https://<bucket-name>.s3.amazonaws.com/index.html
```

❌ Should return **403 Access Denied**

That’s success.

---

## 🧠 What you learned in Phase 7

* Why **public S3 is dangerous**
* Difference between **S3 website vs REST endpoint**
* How CloudFront securely accesses private S3
* Modern **OAC-based security model**
* Real-world CDN security patterns

This is **senior-level AWS knowledge**.

---

## ✅ Phase 7 completion checklist

* [ ] S3 website hosting removed
* [ ] Public access blocked
* [ ] CloudFront still serves content
* [ ] Direct S3 access denied

---

## Interview-ready one-liner (very strong)

> “I hardened the architecture by making S3 private and allowing access only through CloudFront using Origin Access Control, preventing direct public access to storage.”

That’s gold.

---

## What’s next (optional, pick ONE)

You are basically **done** architecturally.

Next best options:
1️⃣ Terraform remote backend (state safety)
2️⃣ CI/CD for frontend + invalidation
3️⃣ Cost guardrails (AWS Budgets)

When ready, say **which one you want** and we’ll do it cleanly.

You’ve built something solid 👏
