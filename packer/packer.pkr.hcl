packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.2"
    }
  }
}

source "amazon-ebs" "app" {
  region        = var.aws_region
  source_ami    = var.source_ami
  instance_type = "t3.micro"
  ssh_username  = "root"

  ami_name = "app-{{timestamp}}"

  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  associate_public_ip_address = true
}


build {
  sources = ["source.amazon-ebs.app"]

  provisioner "file" {
    source      = "../"   # Path to your local workspace (relative to packer directory)
    destination = var.src_dir
  }

  provisioner "shell" {
    script = "scripts/bootstrap.sh"
    environment_vars = [
      "APP_DIR=${var.app_dir}",
      "RUN_COMMANDS=${join("::", var.run_commands)}"
    ]
  }
}
