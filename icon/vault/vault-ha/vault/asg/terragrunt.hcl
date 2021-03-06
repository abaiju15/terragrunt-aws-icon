terraform {
  source = "github.com/hashicorp/terraform-aws-vault//modules/vault-cluster"
}
include {
  path = find_in_parent_folders()
}

locals {
  # Dependencies
  sg = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("sg")}/security-groups/sg-prep"
}

dependencies {
  paths = [local.sg, "../packer-ami", "../keys"]
}

dependency "sg" {
  config_path = local.sg
}

dependency "keys" {
  config_path = "../keys"
}

dependency "packer_ami" {
  config_path = "../packer-ami"
}

inputs = {
  name = "vault"

  cluster_name = "icon-vault"
  ami_id = dependency.packer_ami.outputs.ami_id

  instance_type = "t2.micro"
  vpc_id = dependency.vpc.outputs.vpc_id

  additional_security_group_ids = [dependency.sg.outputs.this_security_group_id]

  allowed_inbound_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]

  allowed_inbound_ssh_security_group_ids = [dependency.bastion_sg.outputs.this_security_group_id]

  user_data = <<-EOF
              #!/bin/bash
              /opt/vault/bin/run-vault --tls-cert-file /opt/vault/tls/vault.crt.pem --tls-key-file /opt/vault/tls/vault.key.pem
              EOF

  cluster_size = 3
  cluster_tag_key = "vault-servers"
  cluster_tag_value = "auto-join"
  availability_zones = dependency.vpc.outputs.azs
  subnet_ids = dependency.vpc.outputs.public_subnets
  ssh_key_name = dependency.keys.outputs.key_name
}