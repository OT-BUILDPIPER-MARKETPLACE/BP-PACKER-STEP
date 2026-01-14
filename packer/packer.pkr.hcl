packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
  }
}

########################
# Variables
########################

variable "aws_region" {
  type = string
}

variable "source_ami" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "app_dir" {
  type    = string
  default = "/var/www/html"
}

variable "src_dir" {
  type    = string
  default = "/tmp/app"
}

variable "run_commands" {
  type    = string
  default = ""
}

########################
# Source
########################

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

########################
# Build
########################

build {
  sources = ["source.amazon-ebs.app"]

  provisioner "file" {
    source      = "../"
    destination = var.src_dir
  }

  provisioner "shell" {
    script = "/home/buildpiper/packer/scripts/bootstrap.sh"
    environment_vars = [
      "APP_DIR=${var.app_dir}",
      "RUN_COMMANDS=${var.run_commands}"
    ]
  }
}
