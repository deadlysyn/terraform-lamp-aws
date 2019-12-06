# See vars.tf for descriptions of each item...

env_name = "usefulTagToRecognizeCreatedResources"
region   = "us-east-2"

web_domain        = "yourdomain.tld"
alt_names         = ["www.yourdomain.tld", "somehost.yourdomain.tld"]
web_message       = "Hello World!"
web_instance_type = "t2.nano"
web_count_min     = "2"
web_count_max     = "4"
web_port          = "80"
lb_port           = "443"

db_instance_type = "db.t2.micro"

vpc_cidr     = "10.1.0.0/16"
public_cidr  = "10.1.1.0/24"
private_cidr = "10.1.2.0/24"
