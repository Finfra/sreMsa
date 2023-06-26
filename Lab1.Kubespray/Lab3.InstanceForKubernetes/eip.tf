resource "aws_eip" "vm_eip" {
  count         = var.instance_count
  domain = "vpc"
  tags = {
    Name = format("vm_eip_0%d", count.index + 1)
  }
}
resource "aws_eip_association" "eip_assoc" {
  count         = var.instance_count
  instance_id   = aws_instance.vm0[count.index].id
  allocation_id = aws_eip.vm_eip[count.index].id
  # count = length(local.eni_ips_list)
  # network_interface_id = aws_network_interface.my_eni.id
  # private_ip_address = local.eni_ips_list[count.index]
  # allocation_id =   aws_eip.lb[count.index].id

}
