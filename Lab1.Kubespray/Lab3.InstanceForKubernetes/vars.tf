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
    eu-west-1      = "ami-0776c814353b4814d"
    ap-northeast-2 = "ami-0e6f2b2fa0ca704d0"
    us-east-1      = "ami-0eac975a54dfee8cb"
  }
} 


variable "instance_count" {
  default = "3"
}


variable "instance_type" {
  default = "t2.small"
}
