variable "aws_region" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "ami_id" {}