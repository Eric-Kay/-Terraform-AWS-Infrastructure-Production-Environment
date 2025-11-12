

# 🏗️ Terraform AWS Infrastructure – Production Environment

## 📘 Overview

This Terraform project provisions a **production-ready AWS environment** built using modular, reusable infrastructure code.  
It includes:

- A **dedicated VPC** with public and private subnets.
 
- A **stand-alone EC2 test server** for development or validation .
  
- **Remote Terraform state management** using **S3** (for state storage) and **DynamoDB** (for state locking)

The setup follows AWS and Terraform best practices for scalability, consistency, and secure collaboration.

---

## 🏗️ Architecture

```

+-------------------------------------------+

| AWS Account                                         |
| --------------------------------------------------- |
| VPC (10.200.0.0/16)                                 |
| ├── Public Subnets (x3)                             |
| │     └── Stand-alone EC2 Server                    |
| ├── Private Subnets (x3)                            |
| └── Internet Gateway / Routing                      |
|                                                     |
| Remote Backend:                                     |
| ├── S3 Bucket: my-terraform-state-bucket11212025new |
| └── DynamoDB Table: terraform-locks                 |
| +-------------------------------------------+       |

```

---

## ⚙️ Repository Structure

```

terraform-aws-prod/
│
├── backend/
│   └── backend.tf               # Provisions S3 + DynamoDB for Terraform backend
│
├── main/
│   ├── main.tf                  # Root infrastructure (VPC, EC2, etc.)
│   ├── backend.tf               # Remote state configuration using S3 + DynamoDB
│   ├── variables.tf             # (optional) Input variables
│   ├── outputs.tf               # (optional) Outputs from modules
│
├── modules/
│   ├── aws-network/             # Custom VPC and subnet module
│   └── aws-testserver/          # EC2 instance module
│
└── README.md                    # Project documentation (this file)

````

---

## 🧱 Step 1: Bootstrap Backend Infrastructure

Before using the main Terraform configuration, you must create the **remote backend** (S3 + DynamoDB).  
This ensures Terraform state files are securely stored and locked for team collaboration.

### 📄 `backend/backend.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

# -------------------------------
# S3 Bucket for Terraform State
# -------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket11212025new" # Change to a unique name

  tags = {
    Name        = "terraform-state"
    Environment = "infrastructure"
  }
}

# Enable versioning for state history
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption (SSE-S3 by default)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# -------------------------------
# DynamoDB Table for State Locking
# -------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "infrastructure"
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
````

### 🧭 To create the backend:

```bash
cd backend/
terraform init
terraform apply
```

Once complete, note the output:

```
s3_bucket_name = "my-terraform-state-bucket11212025new"
dynamodb_table_name = "terraform-locks"
```

---

## 🧩 Step 2: Configure Remote Backend in Main Infrastructure

In the main environment, Terraform uses the backend you created above.

### 📄 `main/backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket11212025new"
    key            = "terraform/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

> ⚠️ **Important:**
> Run `terraform init -reconfigure` in the `main/` directory after the backend resources have been created.

---

## 🧩 Step 3: Deploy the Main Infrastructure

The main environment provisions your **production VPC** and **stand-alone server** using Terraform modules.

### 📄 `main/main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

module "vpc_prod" {
  source               = "../modules/aws-network"
  env                  = "prod"
  vpc_cidr             = "10.200.0.0/16"
  public_subnet_cidr   = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  private_subnet_cidr  = ["10.200.11.0/24", "10.200.22.0/24", "10.200.33.0/24"]

  tags = {
    Owner   = "eric_devops"
    Code    = "777766"
    Project = "SuperProject"
  }
}

module "stand-alone-server" {
  source    = "../modules/aws-testserver"
  name      = "eric_devops"
  subnet_id = module.vpc_prod.public_subnets_id[2]
}
```

### 🧭 Deploy it:

```bash
cd main/
terraform init -reconfigure
terraform plan
terraform apply
```

---

## 🏷️ Variables and Tags

| Variable              | Description                       | Example                     |
| --------------------- | --------------------------------- | --------------------------- |
| `env`                 | Environment name                  | `"prod"`                    |
| `vpc_cidr`            | VPC CIDR block                    | `"10.200.0.0/16"`           |
| `public_subnet_cidr`  | List of public subnet CIDRs       | `["10.200.1.0/24", ...]`    |
| `private_subnet_cidr` | List of private subnet CIDRs      | `["10.200.11.0/24", ...]`   |
| `tags`                | Metadata applied to AWS resources | `{ Owner = "eric_devops" }` |

---

## 🔐 Remote State Resources

| Component          | Name                                   | Purpose                               |
| ------------------ | -------------------------------------- | ------------------------------------- |
| **S3 Bucket**      | `my-terraform-state-bucket11212025new` | Stores Terraform state files          |
| **DynamoDB Table** | `terraform-locks`                      | Manages state locking for concurrency |

---

## 🧰 Troubleshooting

| Issue                        | Possible Cause                       | Fix                                                       |
| ---------------------------- | ------------------------------------ | --------------------------------------------------------- |
| `Error acquiring state lock` | Another Terraform process is running | Wait or remove DynamoDB lock manually                     |
| `AccessDenied` when using S3 | IAM permissions insufficient         | Check your AWS credentials or policy                      |
| Backend not initializing     | Backend not yet created              | Run backend setup first (`cd backend && terraform apply`) |

---

## 🤝 Contributing

We welcome contributions, bug fixes, and module enhancements.
Please:

1. Fork this repository
2. Create a feature branch
3. Submit a Pull Request with clear details

---

## 🪪 License

This project is licensed under the **MIT License**.
See the [LICENSE](LICENSE) file for details.

---

## 🌐 References

* [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [Terraform Remote State Backend Guide](https://developer.hashicorp.com/terraform/language/state/remote)
* [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
* [AWS DynamoDB Documentation](https://docs.aws.amazon.com/amazondynamodb/)

---

💡 *Maintained by* **Eric DevOps** — *Infrastructure as Code for scalable AWS environments.*

```


