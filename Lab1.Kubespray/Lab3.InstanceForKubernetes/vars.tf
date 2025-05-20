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
    eu-west-1      = "ami-01cc3721c85804c6d"
    ap-northeast-2 = "ami-02501420b6298dfc3"
    us-east-1      = "ami-06164a81b7dc7b2b1"
  }
} 


variable "instance_count" {
  default = "3"
}


variable "instance_type" {
  default = "t2.small"
}
