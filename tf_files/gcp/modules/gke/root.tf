data "google_compute_zones" "available" {}

data "google_storage_boject_signed_url" artifiact {
	bucket = "squidwhitelist"
	path = "squidwhitelist"
}

resource "google_container_cluster" "primary" {
  name                   = "${var.cluster_name}"
  zone                   = "${data.google_compute_zones.available.names[0]}"
  initial_node_count     = 3
  network                = "${var.vpc_self_link}"
  subnetwork             = "${var.node_subnetwork}"
  private_cluster        = true
  master_ipv4_cidr_block = "172.${var.vpc_octet2}.${var.vpc_octet3+0}.${var.cluster_index+16}/28"

  master_authorized_networks_config = {
    cidr_blocks = [
      {
        display_name = "internal"
        cidr_block   = "${google_compute_instance.admin_box.network_interface.0.access_config.0.assigned_nat_ip}/32"
      },
    ]
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods"
    services_secondary_range_name = "k8s-services"
  }

  # 
  # Not sure how to use this block - ugh
  #
  #network_policy         = {
  #  provider = ""
  #  enabled = true
  #}

  additional_zones = [
    "${data.google_compute_zones.available.names[1]}",
  ]
  maintenance_policy {
    daily_maintenance_window {
      start_time = "07:00"
    }
  }
  master_auth {
    username = "admin"
    password = "${var.k8s_master_password}"
  }
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels {
      environment = "${var.cluster_name}"
    }

    machine_type = "n1-standard-1"

    service_account = "${var.k8s_node_service_account}"
    tags            = ["gen3", "k8s-node", "${var.cluster_name}"]
  }
}

// let's spin up an adminvm in the subnet too ...
// also serves as NAT gateway for now
resource "google_compute_instance" "admin_box" {
  name                      = "${var.cluster_name}-admin"
  machine_type              = "n1-standard-1"
  zone                      = "${data.google_compute_zones.available.names[0]}"
  allow_stopping_for_update = true
  can_ip_forward            = true

  tags = ["gen3", "k8s-admin", "${var.cluster_name}"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1604-xenial-v20180509"
    }
  }

  // Local SSD disk
  scratch_disk {}

  network_interface {
    subnetwork = "${var.node_subnetwork}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    startup-script = <<EOF
#!/bin/bash -xe
#
# from 
#    https://github.com/GoogleCloudPlatform/terraform-google-nat-gateway/blob/master/main.tf
# , but simplified
#
# Enable ip forwarding and nat
sysctl -w net.ipv4.ip_forward=1
# Make forwarding persistent.
sed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
ethernet=$(ifconfig -s | grep -e ^e | awk '{ print $1 }' | head -1)
iptables -t nat -A POSTROUTING -o "$ethernet" -j MASQUERADE
EOF
  }

  service_account {
    #scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email  = "${var.admin_box_service_account}"
    scopes = ["cloud-platform"]
  }
}

#
# Route to internet through NAT gateway vm
#
resource "google_compute_route" "k8s_nat" {
  name                   = "${var.cluster_name}-k8s-nat"
  dest_range             = "0.0.0.0/0"
  network                = "${var.vpc_self_link}"
  next_hop_instance      = "${google_compute_instance.admin_box.name}"
  next_hop_instance_zone = "${google_compute_instance.admin_box.zone}"
  priority               = 900
  tags                   = ["k8s-node"]
}

// let's spin up a proxyvm in the subnet too ...
resource "google_compute_instance" "squid_box" {
  name                      = "${var.cluster_name}-squid"
  machine_type              = "n1-standard-1"
  zone                      = "${data.google_compute_zones.available.names[0]}"
  allow_stopping_for_update = true
  can_ip_forward            = true

  tags = ["gen3", "proxy", "${var.cluster_name}"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1604-xenial-v20180509"
    }
  }

  // Local SSD disk
  scratch_disk {}

  network_interface {
    subnetwork = "${var.node_subnetwork}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    startup-script = <<EOF
#!/bin/bash -xe
apt-get update
apt-get install squid -y
service squid stop
echo get aws setup
mkdir -p /root/.aws
echo "[default]" > /root/.aws/config
echo "region = us-east-1" >> /root/.aws/config

echo "[default]" > /root/.aws/credentials
echo "aws_access_key_id = ${aws_iam_access_key.squid_s3_user_key.id}" >> /root/.aws/credentials
echo "aws_secret_access_key = ${aws_iam_access_key.squid_s3_user_key.secret}" >> /root/.aws/credentials
apt-get install -y python3-pip build-essential
pip3 install awscli

cat |xxd -r -ps > /tmp/junk.tar.xz << TARRED
fd377a585a000004e6d6b446020021011c00000010cf58cce027ff06955d
00329d088614cb3f5490349a04f01f441509985ae0b3381cc788c934b017
0a24583daf8429ef17f127d94b4e95596be3317079535c50a21481b26047
62c65a70ed3c429e6db453611df4b1890a2e1e181306070b46f2a121626e
05a23bc5317cd72d56eb3c3f3ea6e50500268d7d5ea4a43cad3fa349ac8c
4c3267a0a5cef75b50d8543240cfaaf2cc34b82c0a284ecc77b55499a26d
05e94b8a8ab20d92b62f9f68e38c8162129815ebc4cb4a1c2fdb5188e37b
f7747f367387cc7d59573aa9c642e3c525f7509321d3d8e68938b629a63d
70781177777bf2bc417b92ced78a6aaae75299a0b480df6734c963b37431
c1cf01b04eed0847b4b92871226b8e203dec2c2eb4ba65d7ac7a39b104c2
dcb05ff8d70f8bd3ccc1d6e6234ab7b13cf5d9a2663217b3eee0b82f6326
941368b74a6479cab56bb167c45dddc3839fe4d51714598467f6bb1b8be9
8898b8312f8e9342878bd8e8484e41ad250ed6710d7aad519e571a95ed98
744da62eb04e7cf74156d0f28349a7c7b1084b6e55e49deb42e9d1267998
9c537f2ad01623007f3cd6c4bba788cbd034946faadc987c1173bbb1c0e7
adae2aeb835b2e3ce19bf6176635bd573dfeb321309eeefe608a5242f350
29f2a9d1306a8fda382d5c2144a95bd4e00a2fa1e61a0f08be790f5bba6d
b7cbd79e5632d39d14cb1700bcd67e86a0eeceb3103dc0f9afeb07d07cfa
e2ea72d4d274a979b59b1b26188ca81e40bdfe9f8b280a81e00f1c9b9755
1043dc2344eb32881dad96598262acc7e94904907a5b3e8f1194f16cab12
06de7d4c093d959c5d4e42b7efa3903a2190db85e561c048f3261df7eb3c
929dbea3618f14f0784a4770370ade10356c9c336db47265a026a1cc9dbb
e5eb035ef06fd6a0ee511b40a20f33c53d231a4e0e4acfc4bb87ac93a1fc
a99a94248dddd571448075dac5b3c832fef34fcddc488c5f710c979add9f
db9cda0603244561b72f806ea3f232d8a05b659deff071e9500075490a56
6fa6ac15b367dd60e71907d3e7d3999604ee890f4ddff819f59cb14a59e1
e35b50efcaa5a4a028ce623a70bddb1e560eb6c38c469b189b6f6c23eae7
91af1965a9659e7e807a81c45326379866d11a00ea96923253c4e5336cc1
3bea885a88a9820f5d93c7b8dd2c4b99506110a0ca41f96419fb8a1afecf
34a0332c3f80a12ede4e6958fab693e35486b9708ae1651baf7c73710e8e
345a95935262a7e02c2c6cddd3f3bc092e419f8d8944ebfc3a91a73de9d0
2bb60c94a9fe26cd86e9b73ef5232d6d5be9440e65e8a64affbe4e8e0284
24d4d61c07db153254cfff93602d8bbf318e512eb6285c140ac36da72474
175041194a057a86f83699ec5654d0b2066508ef0ab8eaaa8ebc6deb966b
d2f429b6d38c39f6bee92567a8474ad207bb751939e1b00e01f645328722
1a96dac5a67d34f29dfcf1a6485c97b60f2a08991af07e706248ee23907d
cd4618fc9a9346cbde9dc071969e86addf4d37dd6955b8285ad2493e865b
6a758405fca4eb5606efad2d328ba4ebf296f131f71f53e3e2fec0fd9523
7464c8deaa82045a1fcc1cbae11584d3f0ae897ac4ef6edb5ae8545b3f47
388bae3363596aa733f8c8fc0d5922437a6c88826ef4c00368d651377f34
ac5e41b63bfb4203b79e5ed782fbe927d2ab27f155f57ed0215ec1e39d49
f03aba9afdb9ce5d22a6530b0f5b8cae89e73d3ab104a8eedd8bbc4bbbb8
078a3271a814ed34a67fc76eb662200e7ed0a737798437123f9e5f73aa2e
c18dfda2222fd4ef38eb802917c2b66a5837ba4798b324b693a433f6d601
c82092d3cf30ea99ed535d53f906222800310442ad73e171c8adc12aad25
888e7ae36c02e0c2ead752314ade5cd47fa6f94cd8fb4fa431d5b26d2e8e
148ffc3ff1de4be3a88757647a04b399c4378e4f30175411946bc082cd1f
c4e12ad32c581f0fc80432b5dcd132653ce61b1ae24cc48e96fd1b63b8ce
2011ca72c7d8943e9f9ecf6c4c63120415cf1698289b17569e7584535a30
fc006e14f081e8a407397d6ea490049ff3fdbb38ed25e23881420db07516
afa4717a31c6c8a1b71a2d4e13d2f9f539bc7e42ad6a22a8e52b669a8f8f
0d06af0b66f177407c717ddbb89029511c25cf5ba537ee73728bef3b8c09
5972893cfc83cc32ad8b0c479de53593e55a8938f15974bf7467f91aab5e
d642905f03a4ee1ed40b3b374ab1d1373b01dffcaa33085221068d5f3c26
2a1b1d9e776fe02d1cb99ec8e44751dab70d4f151a683dcca2f78e8f67ff
e3add782a8bf74e2de501185748c29cbd21a87d098800b15fc6f981f2cb8
15b8b7987431d5ad522c544859e50d8876dec122b1f1620d404037626b4f
ebcb04a7d90000000000850d0f2ee2d6e2bc0001b10d805000003748b66b
b1c467fb020000000004595a
TARRED
tar -C / -xJf /tmp/junk.tar.xz
mkdir -p /var/cache/squid && chown proxy:proxy /var/cache/squid
squid -z
wget '${data.google_storage_object_signed_url.artifact.signed_url}' -O /etc/squid.whitelist
service squid start
EOF
  }

  service_account {
    #scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email  = "${var.admin_box_service_account}"
    scopes = ["cloud-platform"]
  }
}
