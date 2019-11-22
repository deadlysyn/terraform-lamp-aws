#!/bin/bash

# WIP - aws cli install required
#INSTANCE_ID=(curl http://169.254.169.254/latest/meta-data/instance-id)
#CURRENT_TAG=(aws ec2 --region eu-west-1 describe-tags | grep Value | awk {'print $2'})
#aws ec2 create-tags --resources {INSTANCE_ID} --tags Key=Name,Value={CURRENT_TAG}-{INSTANCE_ID}

DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install nginx -y

cat >/var/www/html/index.html <<EOF
<html>
<head>
  <title>Success!</title>
</head>
<body>
  <h1>${web_message}</h1>
  <ul>
    <li><b>RDS endpoint:</b> ${db_endpoint}</li>
    <li><b>Database name:</b> ${db_name}</li>
    <li><b>Database user:</b> ${db_username}</li>
    <li><b>Database password:</b> Yeah right! :-)</li>
    <li><b>Database status:</b> ${db_status}</li>
  </ul>
  <pre>
    $(systemctl status nginx)
  </pre>
</body>
</html>
EOF
