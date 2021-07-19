
resource "aws_eip" "example" {
 count         = var.instance_count
 vpc = true
}
