
/*
======================================
SSH key pair to access resources
======================================
*/
resource "aws_key_pair" "admin" {
    key_name   = "${var.name}_admin_key"
    public_key = file(var.ssh_key)

    tags = {
        Name = "${var.name}_admin_key"
    }
}
