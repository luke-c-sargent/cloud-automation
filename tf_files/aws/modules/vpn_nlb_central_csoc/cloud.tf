### Logging stuff

resource "aws_cloudwatch_log_group" "vpn_log_group" {
  name              = "${var.env_vpn_nlb_name}_log_group"
  retention_in_days = 1827

  tags {
    Environment  = "${var.env_vpn_nlb_name}"
    Organization = "Basic Services"
  }
}

## ----- IAM Setup -------


resource "aws_iam_role" "vpn-nlb_role" {
  name = "${var.env_vpn_nlb_name}_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# These VPN VMs should only have access to Cloudwatch and nothing more

data "aws_iam_policy_document" "vpn_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:GetLogEvents",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy",
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    effect    = "Allow"
    resources = ["${aws_s3_bucket.vpn-certs-and-files.arn}", "${aws_s3_bucket.vpn-certs-and-files.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = ["${aws_s3_bucket.vpn-certs-and-files.arn}", "${aws_s3_bucket.vpn-certs-and-files.arn}/*"]
  }

}

#resource "aws_iam_role_policy" "vpn_policy" {
#  name   = "${var.env_vpn_nlb_name}_policy"
#  policy = "${data.aws_iam_policy_document.vpn_policy_document.json}"
#  role   = "${aws_iam_role.vpn-nlb_role.id}"
#}

resource "aws_iam_instance_profile" "vpn-nlb_role_profile" {
  name = "${var.env_vpn_nlb_name}_vpn-nlb_role_profile"
  role = "${aws_iam_role.vpn-nlb_role.id}"
}

resource "aws_iam_policy" "vpn_policy" {
  name        = "${var.env_vpn_nlb_name}_policy"
  description = "Cloud watch and S3 policy"
  policy      = "${data.aws_iam_policy_document.vpn_policy_document.json}"
}

#resource "aws_iam_role_policy_attachment" "vpn_policy_attachment" {
#  role       = "${aws_iam_role.vpn-nlb_role.name}"
#  policy_arn = "${aws_iam_policy.vpn_policy.arn}"
  
#}

resource "aws_iam_policy_attachment" "vpn_policy_attachment" {
  name        = "${var.env_vpn_nlb_name}_policy_attach"
  roles       = ["${aws_iam_role.vpn-nlb_role.name}"]
  policy_arn = "${aws_iam_policy.vpn_policy.arn}"
  users = ["${aws_iam_user.vpn_s3_user.name}"]
}


#Launching the pubate subnets for the VPN VMs

data "aws_availability_zones" "available" {}


resource "aws_subnet" "vpn_pub0" {
  vpc_id                  = "${var.env_vpc_id}"
  cidr_block              = "10.128.${var.env_vpc_octet3}.0/27"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags                    = "${map("Name", "${var.env_vpn_nlb_name}_pub0", "Organization", "Basic Service", "Environment", var.env_vpn_nlb_name)}"
}

resource "aws_subnet" "vpn_pub1" {
  vpc_id                  = "${var.env_vpc_id}"
  cidr_block              = "10.128.${var.env_vpc_octet3}.32/27"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  tags                    = "${map("Name", "${var.env_vpn_nlb_name}_pub1", "Organization", "Basic Service", "Environment", var.env_vpn_nlb_name)}"
}

resource "aws_subnet" "vpn_pub2" {
  vpc_id                  = "${var.env_vpc_id}"
  cidr_block              = "10.128.${var.env_vpc_octet3}.64/27"
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
  tags                    = "${map("Name", "${var.env_vpn_nlb_name}_pub2", "Organization", "Basic Service", "Environment", var.env_vpn_nlb_name)}"
}

resource "aws_subnet" "vpn_pub3" {
  vpc_id                  = "${var.env_vpc_id}"
  cidr_block              = "10.128.${var.env_vpc_octet3}.96/27"
  availability_zone = "${data.aws_availability_zones.available.names[3]}"
  tags                    = "${map("Name", "${var.env_vpn_nlb_name}_pub3", "Organization", "Basic Service", "Environment", var.env_vpn_nlb_name)}"
}

resource "aws_subnet" "vpn_pub4" {
  vpc_id                  = "${var.env_vpc_id}"
  cidr_block              = "10.128.${var.env_vpc_octet3}.128/27"
  availability_zone = "${data.aws_availability_zones.available.names[4]}"
  tags                    = "${map("Name", "${var.env_vpn_nlb_name}_pub4", "Organization", "Basic Service", "Environment", var.env_vpn_nlb_name)}"
}

resource "aws_subnet" "vpn_pub5" {
  vpc_id                  = "${var.env_vpc_id}"
  cidr_block              = "10.128.${var.env_vpc_octet3}.160/27"
  availability_zone = "${data.aws_availability_zones.available.names[5]}"
  tags                    = "${map("Name", "${var.env_vpn_nlb_name}_pub5", "Organization", "Basic Service", "Environment", var.env_vpn_nlb_name)}"
}





resource "aws_route_table_association" "vpn_nlb0" {
  subnet_id      = "${aws_subnet.vpn_pub0.id}"
  route_table_id = "${var.env_pub_subnet_routetable_id}"
}

resource "aws_route_table_association" "vpn_nlb1" {
  subnet_id      = "${aws_subnet.vpn_pub1.id}"
  route_table_id = "${var.env_pub_subnet_routetable_id}"
}

resource "aws_route_table_association" "vpn_nlb2" {
  subnet_id      = "${aws_subnet.vpn_pub2.id}"
  route_table_id = "${var.env_pub_subnet_routetable_id}"
}


resource "aws_route_table_association" "vpn_nlb3" {
  subnet_id      = "${aws_subnet.vpn_pub3.id}"
  route_table_id = "${var.env_pub_subnet_routetable_id}"
}

resource "aws_route_table_association" "vpn_nlb4" {
  subnet_id      = "${aws_subnet.vpn_pub4.id}"
  route_table_id = "${var.env_pub_subnet_routetable_id}"
}

resource "aws_route_table_association" "vpn_nlb5" {
  subnet_id      = "${aws_subnet.vpn_pub5.id}"
  route_table_id = "${var.env_pub_subnet_routetable_id}"
}




# launching the network load balancer for the VPN VMs

resource "aws_lb" "vpn_nlb" {
  name               = "${var.env_vpn_nlb_name}-prod"
  internal           = false
  load_balancer_type = "network"
    subnet_mapping {
       subnet_id    =  "${aws_subnet.vpn_pub0.id}"
  }
   subnet_mapping {
       subnet_id    =  "${aws_subnet.vpn_pub1.id}"
  }
   subnet_mapping {
       subnet_id    =  "${aws_subnet.vpn_pub2.id}"
  }
   subnet_mapping {
       subnet_id    =  "${aws_subnet.vpn_pub3.id}"
  }
   subnet_mapping {
       subnet_id    =  "${aws_subnet.vpn_pub4.id}"
  }
   subnet_mapping {
       subnet_id    =  "${aws_subnet.vpn_pub5.id}"
  }


  
   

  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true

  tags {
    Environment = "production"
  }
}
# For VPN TCP  traffic
resource "aws_lb_target_group" "vpn_nlb-tcp" {
  name     = "${var.env_vpn_nlb_name}-prod-tcp-tg"
  port     = 1194
  protocol = "TCP"
  vpc_id   = "${var.env_vpc_id}"
  #proxy_protocol_v2 = "True"
  }

resource "aws_lb_listener" "vpn_nlb-tcp" {
  load_balancer_arn = "${aws_lb.vpn_nlb.arn}"
  port              = "1194"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.vpn_nlb-tcp.arn}"
    type             = "forward"
  }
}


# For VPN  QR code  traffic
resource "aws_lb_target_group" "vpn_nlb-qr" {
  name     = "${var.env_vpn_nlb_name}-prod-qr-tg"
  port     = 443
  protocol = "TCP"
  vpc_id   = "${var.env_vpc_id}"
  #proxy_protocol_v2 = "True"
  }

resource "aws_lb_listener" "vpn_nlb-qr" {
  load_balancer_arn = "${aws_lb.vpn_nlb.arn}"
  port              = "443"
  protocol          = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.vpn_nlb-qr.arn}"
    type             = "forward"
  }
}




# Auto scaling group for VPN nlb

resource "aws_launch_configuration" "vpn_nlb" {
  name_prefix = "${var.env_vpn_nlb_name}_autoscaling_launch_config"
  image_id = "${data.aws_ami.public_vpn_ami.id}"
  instance_type = "t2.medium"
 # instance_type = "m5.xlarge"
  security_groups = ["${aws_security_group.vpnnlb_in.id}", "${aws_security_group.vpnnlb_out.id}"]
  key_name = "${var.ssh_key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.vpn-nlb_role_profile.id}"
  #iam_instance_profile   = "${aws_iam_instance_profile.vpn-certs-and-files_reader.id}"
  #iam_instance_profile   = "${aws_iam_instance_profile.vpn-certs-and-files_writer.id}"
  associate_public_ip_address = true
  

  depends_on = ["aws_iam_instance_profile.vpn-nlb_role_profile"]
 #depends_on = ["aws_iam_instance_profile.vpn-certs-and-files_reader"]
  #depends_on = ["aws_iam_instance_profile.vpn-certs-and-files_writer"]

user_data = <<EOF
#!/bin/bash
cd /home/ubuntu
sudo git clone https://github.com/uc-cdis/cloud-automation.git
sudo chown -R ubuntu. /home/ubuntu/cloud-automation
cd /home/ubuntu/cloud-automation
git pull

# checkout to the vpn branch for testing purposes
git checkout feat/csocvpn_setup
git pull

sudo chown -R ubuntu. /home/ubuntu/cloud-automation

echo "127.0.1.1 ${var.env_vpn_nlb_name}" | sudo tee --append /etc/hosts
#sudo hostnamectl set-hostname ${var.env_vpn_nlb_name}

sudo apt -y update
sudo DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade| sudo tee --append /var/log/bootstrapping_script.log
sudo apt-get install -y python3-pip build-essential
sudo pip3 install awscli

sudo apt-get autoremove -y
sudo apt-get clean
sudo apt-get autoclean

# This is to modify the S3 scripts and openvpn install script to use the specific VPN bucket in S3

sudo cp   -r /home/ubuntu/cloud-automation/files/openvpn_management_scripts /root

sed -i "s/WHICHVPN/${var.env_vpn_nlb_name}/" /root/openvpn_management_scripts/push_to_s3.sh
sed -i "s/WHICHVPN/${var.env_vpn_nlb_name}/" /root/openvpn_management_scripts/recover_from_s3.sh
sed -i "s/WHICHVPN/${var.env_vpn_nlb_name}/" /root/openvpn_management_scripts/install_ovpn.sh

aws s3 ls s3://vpn-certs-and-files/${var.env_vpn_nlb_name}/ && /root/openvpn_management_scripts/recover_from_s3.sh

cd /home/ubuntu
## WORK ON THIS TO POINT TO THE VPN FLAVOR SCRIPT
sudo bash "${var.bootstrap_path}${var.bootstrap_script}" 2>&1 |sudo tee --append /var/log/bootstrapping_script.log

mkdir -p /root/.aws
echo "[default]" > /root/.aws/config
echo "region = us-east-1" >> /root/.aws/config

echo "[default]" > /root/.aws/credentials
echo "aws_access_key_id = ${aws_iam_access_key.vpn_s3_user_key.id}" >> /root/.aws/credentials
echo "aws_secret_access_key = ${aws_iam_access_key.vpn_s3_user_key.secret}" >> /root/.aws/credentials



EOF

lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "vpn_nlb" {
  name = "${var.env_vpn_nlb_name}_autoscaling_grp"
#If you define a list of subnet IDs split across the desired availability zones set them using vpc_zone_identifier 
# and there is no need to set availability_zones.
# (tcps://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#availability_zones).


  desired_capacity = 1
  max_size = 1
  min_size = 1
  target_group_arns = ["${aws_lb_target_group.vpn_nlb-tcp.arn}","${aws_lb_target_group.vpn_nlb-qr.arn}",]
  vpc_zone_identifier = ["${aws_subnet.vpn_pub0.id}", "${aws_subnet.vpn_pub1.id}", "${aws_subnet.vpn_pub2.id}", "${aws_subnet.vpn_pub3.id}", "${aws_subnet.vpn_pub4.id}", "${aws_subnet.vpn_pub5.id}"]
  launch_configuration = "${aws_launch_configuration.vpn_nlb.name}"

   tag {
    key                 = "Name"
    value               = "${var.env_vpn_nlb_name}_autoscaling_grp_member"
    propagate_at_launch = true
  }
}




data "aws_ami" "public_vpn_ami" {
  most_recent = true

  filter {
    name   = "name"
 
    values = ["${var.image_name_search_criteria}"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter { 
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${var.ami_account_id}"]
  
}





# Security groups for the CSOC  VPN VM 

resource "aws_security_group" "vpnnlb_in" {
  name        = "${var.env_vpn_nlb_name}-vpnnlb_in"
  description = "security group that only enables ssh from VPC nodes and CSOC"
  vpc_id      = "${var.env_vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment  = "${var.env_vpn_nlb_name}"
    Organization = "Basic Service"
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment  = "${var.env_vpn_nlb_name}"
    Organization = "Basic Service"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment  = "${var.env_vpn_nlb_name}"
    Organization = "Basic Service"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment  = "${var.env_vpn_nlb_name}"
    Organization = "Basic Service"
  }

  lifecycle {
    ignore_changes = ["description"]
  }
}


resource "aws_security_group" "vpnnlb_out" {
  name        = "${var.env_vpn_nlb_name}-vpnnlb_out"
  description = "security group that allow outbound traffics"
  vpc_id      = "${var.env_vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment  = "${var.env_vpn_nlb_name}"
    Organization = "Basic Service"
  }
}





# DNS entry for the CSOC VPN NLB

resource "aws_route53_record" "vpn-nlb" {
  zone_id = "${var.csoc_planx_dns_zone_id}"
  name    = "raryatestvpnv1.planx-pla.net"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.vpn_nlb.dns_name}"]
}


# aws account for s3 storage of VPN certs
resource "aws_iam_user" "vpn_s3_user" {
  name = "${var.environment}-vpn-s3-user"
}

resource "aws_iam_access_key" "vpn_s3_user_key" {
  user = "${aws_iam_user.vpn_s3_user.name}"
}

resource "aws_s3_bucket" "vpn-certs-and-files" {
  bucket = "vpn-certs-and-files"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags {
    Name        = "vpn-certs-and-files"
    Environment = "${var.environment}"
    Purpose     = "data bucket"
  }
}

#Really????
#resource "aws_iam_role" "vpn-certs-and-files_reader" {
 # name = "bucket_reader_vpn-certs-and-files"
 # path = "/"

  #assume_role_policy = <<EOF
#{
 #   "Version": "2012-10-17",
  #  "Statement": [
   #     {
    #        "Action": "sts:AssumeRole",
     #       "Principal": {
      #         "Service": "ec2.amazonaws.com"
       #     },
        #    "Effect": "Allow",
         #   "Sid": ""
        #}
    #]
#}
#EOF
#}

#data "aws_iam_policy_document" "vpn-certs-and-files_reader" {
  #statement {
   # actions = [
    #  "s3:Get*",
     # "s3:List*",
   # ]

    #effect    = "Allow"
    #resources = ["${aws_s3_bucket.vpn-certs-and-files.arn}", "${aws_s3_bucket.vpn-certs-and-files.arn}/*"]
  #}
#}

#resource "aws_iam_policy" "vpn-certs-and-files_reader" {
 # name        = "bucket_reader_vpn-certs-and-files"
 # description = "Read vpn-certs-and-files"
 # policy      = "${data.aws_iam_policy_document.vpn-certs-and-files_reader.json}"
#}

#resource "aws_iam_role_policy_attachment" "vpn-certs-and-files_reader" {
 # role       = "${aws_iam_role.vpn-certs-and-files_reader.name}"
 # policy_arn = "${aws_iam_policy.vpn-certs-and-files_reader.arn}"
#}



#resource "aws_iam_instance_profile" "vpn-certs-and-files_reader" {
#  name = "bucket_reader_vpn-certs-and-files"
#  role = "${aws_iam_role.vpn-certs-and-files_reader.id}"
#}

#----------------------

#resource "aws_iam_role" "vpn-certs-and-files_writer" {
 # name = "bucket_writer_vpn-certs-and-files"
 # path = "/"

  #assume_role_policy = <<EOF
#{
 #   "Version": "2012-10-17",
  #  "Statement": [
   #     {
    #        "Action": "sts:AssumeRole",
     #       "Principal": {
      #         "Service": "ec2.amazonaws.com"
       #     },
        #    "Effect": "Allow",
         #   "Sid": ""
        #}
    #]
#}
#EOF
#}

resource "aws_s3_bucket_policy" "vpn-bucket-policy" {
  bucket = "${aws_s3_bucket.vpn-certs-and-files.id}"
  policy =<<POLICY
{
    "Version": "2012-10-17",
    "Id": "Policy1533585028918",
    "Statement": [
        {
            "Sid": "Stmt1533585020818",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::433568766270:user/CSOC-vpn-s3-user"
            },
            "Action": "s3:*",
            "Resource": [
               "arn:aws:s3:::vpn-certs-and-files",
               "arn:aws:s3:::vpn-certs-and-files/*"
            ]
        }
    ]
}

POLICY
}



#data "aws_iam_policy_document" "vpn-certs-and-files_writer" {
 # statement {
   # actions = [
    #  "s3:Get*",
    #  "s3:List*",
   # ]

   # effect    = "Allow"
   # resources = ["${aws_s3_bucket.vpn-certs-and-files.arn}", "${aws_s3_bucket.vpn-certs-and-files.arn}/*"]
  #}

  #statement {
    #effect = "Allow"

    #actions = [
     # "s3:PutObject",
     # "s3:GetObject",
    #  "s3:DeleteObject",
   # ]

  #  resources = ["${aws_s3_bucket.vpn-certs-and-files.arn}", "${aws_s3_bucket.vpn-certs-and-files.arn}/*"]
 # }
#}

#resource "aws_iam_policy" "vpn-certs-and-files_writer" {
  #name        = "bucket_writer_vpn-certs-and-files"
  #description = "Read or write vpn-certs-and-files"
 # policy      = "${data.aws_iam_policy_document.vpn-certs-and-files_writer.json}"
#}

#resource "aws_iam_role_policy_attachment" "vpn-certs-and-files_writer" {
 # role       = "${aws_iam_role.vpn-certs-and-files_writer.name}"
  #policy_arn = "${aws_iam_policy.vpn-certs-and-files_writer.arn}"
#}

#resource "aws_iam_instance_profile" "vpn-certs-and-files_writer" {
  #name = "bucket_writer_vpn-certs-and-files"
 # role = "${aws_iam_role.vpn-certs-and-files_writer.id}"
#}


