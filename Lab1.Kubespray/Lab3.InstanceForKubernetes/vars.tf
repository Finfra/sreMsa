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
    eu-west-1      = "ami-0a422d70f727fe93e"
    ap-northeast-2 = "ami-042e76978adeb8c48"
    us-east-1      = "ami-005fc0f236362e99f"
  }
} 


variable "instance_count" {
  default = "3"
}


variable "instance_type" {
  default = "t2.small"
}
