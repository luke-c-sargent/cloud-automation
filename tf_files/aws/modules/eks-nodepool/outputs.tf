
output "asg_id" {
  value = "${aws_autoscaling_group.eks_autoscaling_group.id}"
}

