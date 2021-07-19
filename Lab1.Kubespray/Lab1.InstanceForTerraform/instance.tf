resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_instance" "myinstance" {
  count         = var.instance_count
  ami           = lookup(var.AMIS, var.AWS_REGION)
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mykey.key_name

  # 
  # provisioner "file" {
  #   source      = "installOnEc2.sh"
  #   destination = "/tmp/installOnEc2.sh"
  # }
  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/installOnEc2.sh",
  #     "sudo /tmp/installOnEc2.sh"
  #   ]
  # }
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    user        = var.INSTANCE_USERNAME
    private_key = file(var.PATH_TO_PRIVATE_KEY)
  }
  # connection {
  # user = var.INSTANCE_USERNAME
  # }
  tags = {
  Name = format("Instance-%d", count.index + 1)
  }
}
