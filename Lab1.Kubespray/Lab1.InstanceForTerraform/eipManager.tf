resource "aws_eip" "eip_manager" {
  instance   = element(aws_instance.myinstance.*.id,count.index)
  count = var.instance_count
  vpc = true
    tags = {
    Name = "eip--${count.index + 1}"
  }
}


