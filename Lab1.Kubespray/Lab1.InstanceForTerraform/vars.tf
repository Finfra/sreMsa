variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "eu-west-1"
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "~/mykey"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "~/mykey.pub"
}
variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}

variable "AMIS" {
  default = {
    eu-west-1      = "ami-0dad359ff462124ca"
    ap-northeast-2 = "ami-00edfb46b107f643c"
    us-east-1      = "ami-085925f297f89fce1"
  }
}


variable "instance_count" {
  default = "1"
}
