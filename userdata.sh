#!/bin/bash
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

cat >index.html <<EOF
<html>
<head>
  <title>Welcome Page</title>
</head>
<body>
  <h1>${web_message}</h1>
  <ul>
    <li><b>RDS endpoint:</b> <pre>${db_endpoint}</pre>
    <li><b>Database name:</b> <pre>${db_name}</pre>
    <li><b>Database user:</b> <pre>${db_username}</pre>
    <li><b>Database status:</b> <pre>${db_status}</pre>
  </ul>
</body>
</html>
EOF

nohup busybox httpd -f -p ${web_port} &
