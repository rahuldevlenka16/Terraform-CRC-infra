Perfect. **Phase 5 is a big milestone** — this is where your site becomes **HTTPS + production-grade**.

We’ll do this **cleanly and safely**, without breaking what already works.

---

# 🔹 Phase 5: CloudFront (CDN + HTTPS)

### Goal of this phase

> Put **CloudFront in front of S3** so users access the site via **HTTPS**, caching, and global edge locations.

After this phase:

* ❌ Users should NOT use the S3 website URL
* ✅ Users access the site via **CloudFront URL**
* ⚠️ S3 is still public (we’ll lock it down later)

---

## ✅ What we will build in Phase 5

* CloudFront distribution
* S3 as origin
* HTTP → HTTPS redirect
* Default caching behavior
* CloudFront URL output

---

## ⚠️ Important design choice (for now)

For **Phase 5**, we will:

* Use **S3 website endpoint** as origin
* Keep bucket public

Why?

* Simpler
* Avoids OAI/OAC complexity for now
* We’ll fix security in **Phase 7**

This is **intentional and correct for learning**.

---

## 1️⃣ Add CloudFront distribution (Terraform)

Add this to **main.tf**:

```hcl
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  is_ipv6_enabled = true
  comment = "Cloud Resume CDN"

  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "s3-website-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-website-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

---

## 2️⃣ Add CloudFront URL output

Add this to **outputs.tf**:

```hcl
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
```

---

## 3️⃣ Apply Terraform

```bash
terraform plan
terraform apply
```

⏳ CloudFront takes **5–15 minutes** to deploy.
Terraform may finish, but CloudFront will still be **In Progress**.

---

## 4️⃣ Test Phase 5 (VERY IMPORTANT)

### A. Wait for deployment

In AWS Console:

* CloudFront → Distribution
* Status: **Deployed**

---

### B. Open CloudFront URL

Terraform will output something like:

```
d3abcxyz.cloudfront.net
```

Open in browser:

```
https://d3abcxyz.cloudfront.net
```

Expected:

* Page loads ✅
* HTTPS lock icon 🔒
* Same content as S3 site

---

### C. Verify redirect

Try:

```
http://d3abcxyz.cloudfront.net
```

It should redirect to HTTPS automatically.

---

## 🧠 What you learned in Phase 5

* Why S3 alone cannot do HTTPS
* How CloudFront sits in front of S3
* Origin vs cache behavior
* Viewer protocol policies
* Why CDN is essential for production

---

## ❗ Common issues & quick fixes

### ❌ 403 / 404 from CloudFront

* S3 website endpoint wrong
* `index.html` missing
* Bucket policy incorrect

### ❌ Still loading old content

* CloudFront cache
* This is normal → fixed later with invalidation or cache headers

---

## ⚠️ Security reminder (important)

Right now:

* S3 is still public
* Anyone can bypass CloudFront

That’s **expected for Phase 5**.

👉 We will **fix this in Phase 7** by:

* Making S3 private
* Allowing access only from CloudFront

---

## ✅ Phase 5 completion checklist

* [x] CloudFront distribution created
* [x] HTTPS works
* [x] Page loads via CloudFront
* [x] HTTP redirects to HTTPS

---

When everything works, reply:

**`done`**

Next → **Phase 6: Custom Domain + ACM + Route 53**
This is where it looks *professional*.
