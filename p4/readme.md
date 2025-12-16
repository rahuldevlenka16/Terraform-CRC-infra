Great. Let’s do **Phase 4: S3 Static Frontend Hosting** — **slow, clear, and testable**.

---

# 🔹 Phase 4: S3 Static Website (Frontend)

### Goal of this phase

> Host a simple static website (`index.html`) on **Amazon S3** using Terraform and verify it loads in a browser.

⚠️ For this phase, we’ll **temporarily allow public access** to keep things simple.
We’ll **lock it down later** when CloudFront is added.

---

## ✅ What we will build

* S3 bucket
* Static website hosting enabled
* Temporary public read access
* Simple `index.html` that loads

---

## 📁 Files you’ll touch

* `main.tf`
* `outputs.tf`
* (new) `frontend/index.html`

---

## 1️⃣ Create the S3 bucket (Terraform)

Add this to **main.tf**:

```hcl
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "cloud-resume-rahul-frontend"  # must be globally unique

  tags = {
    Project = "CloudResume"
  }
}
```

⚠️ If this bucket name already exists in AWS (by anyone), change it slightly.

---

## 2️⃣ Allow public access (TEMPORARY)

Add **below the bucket** in `main.tf`:

```hcl
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

> This is required for **S3 static website hosting**.

---

## 3️⃣ Add bucket policy for public read

```hcl
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAllAccess",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "${aws_s3_bucket.frontend_bucket.arn}/*"
        }
    ]
})
}
```

---

## 4️⃣ Enable static website hosting

```hcl
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }
}
```

---

## 7️⃣ Output the S3 website URL

Add to **outputs.tf**:

```hcl
output "s3_website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
```

---

## 8️⃣ Apply Terraform

```bash
terraform plan
terraform apply
```

---




## 5️⃣ Create a simple frontend page

Create file:

```text
frontend/index.html
```

Content:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Cloud Resume</title>
</head>
<body>
  <h1>Hello from S3!</h1>
  <p>If you see this, Phase 4 works.</p>
</body>
</html>
```

---

## 6️⃣ Upload the file (manual for now)

```bash
aws s3 cp frontend/index.html \
  s3://cloud-resume-rahul-frontend/index.html
```

---



## 9️⃣ Test Phase 4 (IMPORTANT)

Terraform will output something like:

```
cloud-resume-rahul-frontend.s3-website.ap-south-1.amazonaws.com
```

Open it in a browser:

```text
http://cloud-resume-rahul-frontend.s3-website.ap-south-1.amazonaws.com
```

Expected result:

> **Hello from S3!**

✅ If you see the page → Phase 4 is successful.

---

## 🧠 What you learned in Phase 4

* Difference between **S3 REST endpoint vs website endpoint**
* Why public access is required for S3 website hosting
* How Terraform manages storage resources
* How frontend hosting works without servers

---

## ❗ Important note (don’t skip)

This setup is **NOT secure** and **does NOT support HTTPS**.

That’s expected.

👉 **CloudFront in Phase 5 will fix this**.

---

## ✅ Phase 4 completion checklist

* [x] S3 bucket created
* [x] Static website enabled
* [x] `index.html` loads in browser
* [x] Terraform managed everything

---

S3 CP vs SYNC

aws s3 cp

Purpose: Copy specific files or objects from one place to another.

What it does

Copies one file or multiple files (with --recursive)

No comparison of timestamps or sizes (unless you script it)

Always copies what you tell it to

Common use cases

Upload or download a single file

Copy a known set of files

Overwrite an object intentionally

One-time transfers

Examples
# Upload a single file
aws s3 cp file.txt s3://my-bucket/file.txt

# Download a file
aws s3 cp s3://my-bucket/file.txt .

# Copy a folder (blind copy)
aws s3 cp ./data s3://my-bucket/data --recursive

Pros

✔ Simple and predictable
✔ Works like cp in Linux
✔ Good for scripting one-off tasks

Cons

✖ Re-copies files even if unchanged
✖ No delete handling

aws s3 sync

Purpose: Keep two locations in sync.

What it does

Compares file size and last modified time

Copies only new or changed files

Can optionally delete files that no longer exist at the source

Common use cases

Backups

Deploying static websites

Mirroring directories

Incremental uploads/downloads

Examples
# Sync local folder to S3
aws s3 sync ./site s3://my-bucket/site

# Sync S3 back to local
aws s3 sync s3://my-bucket/site ./site

# Mirror exactly (dangerous if misused)
aws s3 sync ./site s3://my-bucket/site --delete

Pros

✔ Efficient for large directories
✔ Avoids unnecessary transfers
✔ Ideal for repeat runs

Cons

✖ Slightly slower to start (comparison step)
✖ --delete can remove data if used incorrectly