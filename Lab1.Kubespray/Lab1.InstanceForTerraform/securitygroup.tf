data "aws_ip_ranges" "eu_west" {
  regions  = ["eu-west-1"]
  services = ["ec2"]
}

resource "aws_security_group" "from_eu_west" {
  name = "from_eu_west"

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = data.aws_ip_ranges.eu_west.cidr_blocks
  }
  tags = {
    CreateDate = data.aws_ip_ranges.eu_west.create_date
    SyncToken  = data.aws_ip_ranges.eu_west.sync_token
  }

}
