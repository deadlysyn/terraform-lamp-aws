# Setup

```bash
brew update
brew install awscli
brew install terraform
aws configure
```

If you have the `aws` CLI installed and configured, `terraform` will use those credentials automatically. Otherwise, you need to provide your IAM key and secret via environment:

```bash
export AWS_ACCESS_KEY_ID=$yourAccessKeyID
export AWS_SECRET_ACCESS_KEY=$yourSecretAccessKey
```

The IAM user minimally needs the `AmazonEC2FullAccess` and `AmazonRDSFullAccess` managed policies.

# Usage

This will work with AWS' free tier.

```bash
# unique resource prefix for easy cleanup
ENV_NAME=$(uuidgen | cut -d- -f1)

# prepare
terraform init
terraform plan -out=plan -var="env_name=$ENV_NAME"

# make it so
terraform apply plan

# cleanup
terraform destroy -var="env_name=$ENV_NAME"
```

# Notes and Enhancement Ideas

- Provided CIDRs are further subnetted to create public and private subnets spanning all AZs in the region for HA
- Auto-select latest Ubuntu AMI to work in all regions, but could give filter more thought (e.g. pin version for a real production app)
- Userdata scripts are good for small tweaks, but pre-baked AMI via packer would be better in production
- Used `busybox` to avoid needing to route private subnet through IGW for config/update
- Security groups could be refined
-   RDS is provisioned and details fed into web process, but:
  -   Would be cooler if 'hello world' was injected as SQL and actually read by web server
  -   `engine_version` is MAJOR.MINOR so PATCH upgrades will be automatic
- Adding a proxy layer for TLS termination, caching, etc would be more real-world
- Encrypting all the things might require KMS/TLS and thinking about cert/secret management
- `db_password` comes from `.envrc` (picked up from runtime environment)
- Could support map of tags vs simply using `env_name`, e.g. `environment`, `purpose`, etc.
- Ideally would use modules for common tasks (don't reinvent the wheel, DRY)
- In a modular world, remote state could be leveraged to consume cross-module facts
- This is optimized to fit in free tier, but a real database would need larger instances, replicas, backups, etc.
- As an experiment, random DNS names work...but needs tied into Route53 managed zone.
