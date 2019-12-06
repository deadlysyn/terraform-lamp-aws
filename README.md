# Terraforming LAMP

This repo has an accompanying blog series:

- [Terraforming AWS: Part I](https://blog.devopsdreams.io/terraforming-aws-part-i)
- [Terraforming AWS: Part II](https://blog.devopsdreams.io/terraforming-aws-part-ii)
- [Terraforming AWS: Part III](https://blog.devopsdreams.io/terraforming-aws-part-iii)
- [Squashing Bugs](https://blog.devopsdreams.io/squashing-bugs)
- [Getting Out More](https://blog.devopsdreams.io/getting-out-more)
- [AWS and DNS and TLS, Oh My!](https://blog.devopsdreams.io/aws-dns-and-tls)

What this builds (except it's served over TLS now!):

![Simple LAMP Stack](https://gitlab.com/deadlysyn/terraform-lamp-aws/raw/master/assets/lamp.jpg)

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

_NOTE: The RDS database password is sourced from the `TF_VARS_db_password` variable, which you should export (or set via `.envrc` if you use `direnv`) before running terraform._

This will work with AWS' free tier. Clone this repo, then:

```bash
# adjust as needed
❯ vi terraform.tfvars

# prepare
❯ terraform init
❯ terraform plan -out=plan

# make it so
❯ terraform apply plan

# cleanup
❯ terraform destroy
```

The RDS instance can take 10-15 minutes to provision, and cert validation may take up to 30 minutes (though usually completes much faster)... When all is complete done, you should be able to access `https://web_domain`.

```bash
❯ http https://technopoly.io
HTTP/1.1 200 OK
Connection: keep-alive
Content-Encoding: gzip
Content-Type: text/html
Date: Fri, 06 Dec 2019 04:23:23 GMT
ETag: W/"5de9c9f2-4e5"
Last-Modified: Fri, 06 Dec 2019 03:24:34 GMT
Server: nginx/1.14.0 (Ubuntu)
Transfer-Encoding: chunked

<html>
<head>
  <title>Success!</title>
</head>
<body>
  <h1>Hello World!</h1>
  <ul>
    <li><b>RDS endpoint:</b> terraform-20191206030327354900000007.chbcdfxppube.us-east-2.rds.amazonaws.com:3306</li>
    <li><b>Database name:</b> testdb</li>
    <li><b>Database user:</b> root</li>
    <li><b>Database password:</b> Yeah right! :-)</li>
    <li><b>Database status:</b> available</li>
  </ul>
  <pre>
    â nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2019-12-06 03:24:30 UTC; 3s ago
     Docs: man:nginx(8)
 Main PID: 2134 (nginx)
    Tasks: 2 (limit: 547)
   CGroup: /system.slice/nginx.service
           ââ2134 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
           ââ2136 nginx: worker process

Dec 06 03:24:30 ip-10-1-2-58 systemd[1]: Starting A high performance web server and a reverse proxy server...
Dec 06 03:24:30 ip-10-1-2-58 systemd[1]: nginx.service: Failed to parse PID from file /run/nginx.pid: Invalid argument
Dec 06 03:24:30 ip-10-1-2-58 systemd[1]: Started A high performance web server and a reverse proxy server.
  </pre>
</body>
</html>
```

# Notes and Enhancement Ideas

- Provided CIDRs are further subnetted to create public and private subnets spanning all AZs in the region for HA
- Auto-select latest Ubuntu AMI to work in all regions, but could give filter more thought (e.g. pin version for a real production app)
- Userdata scripts are good for small tweaks, but pre-baked AMI via packer would be better in production
- RDS is provisioned and details fed into web process, but:
  - Would be cooler if 'hello world' was injected as SQL and actually read by web server
  - `engine_version` is MAJOR.MINOR so PATCH upgrades will be automatic
- `db_password` comes from `.envrc` (picked up from runtime environment)
- Could support map of tags vs simply using `env_name`, e.g. `environment`, `purpose`, etc.
- Ideally would use modules for common tasks (don't reinvent the wheel, DRY)
- In a modular world, remote state could be leveraged to consume cross-module facts
- This is optimized to fit in free tier, but a real database would need larger instances, replicas, backups, etc.
