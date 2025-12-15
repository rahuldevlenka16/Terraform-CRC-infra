Perfect. Let’s **start Phase 1** calmly and properly.

---

# 🔹 Phase 1: DynamoDB (Visitor Counter Table)

### Goal of this phase

> Create the DynamoDB table using Terraform and **verify it works**.
> No Lambda, no API, no frontend yet.

If this phase works, everything else builds on top of it.

---

## ✅ What you will build

* One DynamoDB table
* On-demand billing (no cost risk)
* Simple primary key (`id`)

---

## 📁 Folder structure (minimal)

```text
cloud-resume-infra/
├── providers.tf
├── variables.tf
├── main.tf
└── outputs.tf
```

---

## 1️⃣ providers.tf

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

> Use the same region where you are already working.

---

## 2️⃣ variables.tf (optional but good habit)

```hcl
variable "table_name" {
  default = "visitor-count"
}
```

---

## 3️⃣ main.tf (DynamoDB table)

```hcl
resource "aws_dynamodb_table" "visitor_count" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "CloudResume"
  }
}
```

### Why this is correct

* `PAY_PER_REQUEST` → auto scaling, no capacity planning
* `hash_key = id` → simple and perfect for atomic counters
* No GSIs needed (keep it simple)

---

## 4️⃣ outputs.tf

```hcl
output "dynamodb_table_name" {
  value = aws_dynamodb_table.visitor_count.name
}
```

---

## 5️⃣ Run Terraform (important order)

From the project root:

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` when asked.

---

## 6️⃣ Test Phase 1 (VERY IMPORTANT)

### A. Verify in AWS Console

* Go to **DynamoDB**
* You should see table: `visitor-count`
* Status: **ACTIVE**

✅ If you see this → Phase 1 infra is correct

---

### B. (Optional but recommended) Manual test

In DynamoDB console:

1. Open the table
2. Click **Explore table items**
3. Create item:

   * `id` → `counter`
   * `count` → `0` (Number)

This item will be used later by Lambda.

---








## 🧠 What you learned in Phase 1

* How Terraform talks to AWS
* How state is created
* How DynamoDB on-demand works
* Why atomic counters don’t need locks
* Safe, zero-risk AWS resource creation

---

## ❗ Very important rule before moving on

Do **NOT** continue unless:

* Terraform apply worked without errors
* You can see the table in AWS Console
* You understand **why PAY_PER_REQUEST was chosen**

---

## Next step

When Phase 1 is done, reply with:

**`done`**

Then we’ll move to **Phase 2: IAM + Lambda (compute layer)**
One step at a time, no overwhelm 👍
