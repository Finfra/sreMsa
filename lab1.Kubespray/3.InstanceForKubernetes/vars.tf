variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "ap-northeast-2"
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "~/.ssh/id_rsa"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "~/.ssh/id_rsa.pub"
}
variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}

variable "AMIS" {
  default = {
    eu-west-1      = "ami-0d3bb9c10151c3245"
    ap-northeast-2 = "ami-00e73adb2e2c80366"
    us-east-1      = "ami-0aa28dab1f2852040"
  }
} 


variable "instance_count" {
  default = "3"
}


variable "instance_type" {
  default = "t2.small"
}
