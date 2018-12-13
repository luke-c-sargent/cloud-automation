
variable "vpc_name" {}

variable "pool_name" {}

variable "ec2_keyname" {
  default = "someone@uchicago.edu"
}

variable "instance_type" {
  default = "t2.xlarge"
}

# Almost always the same as the vpc_name -
variable "users_policy" {}

#
# Should the cluster-autoscaler consider these nodes?
# Set to 'enabled' to register with autoscaler
#
variable "scaler_enabled" {
  default = "disabled"
}
