
data "template_file" "ssh_keys" {
  template = "${file("${path.module}/../../../../files/authorized_keys/ops_team")}"
}
