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

variable "instance_type" {
  type    = string
  default = "t3.micro"
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

variable "ami_name" {
  type    = string
  default = "app"
}


variable "root_volume_size" {
  type    = number
  default = 8
}

variable "root_volume_type" {
  type    = string
  default = "gp3"
}

########################
# Source
########################

source "amazon-ebs" "app" {
  region        = var.aws_region
  source_ami    = var.source_ami
  instance_type = var.instance_type
  ssh_username  = "ubuntu"

  ami_name               = "${var.ami_name}-{{timestamp}}"
  iam_instance_profile   = "React-VM-Buildpiper"
  ami_description        = "Nimbus App AMI built by BuildPiper"

  vpc_id                  = var.vpc_id
  subnet_id               = var.subnet_id
  security_group_id       = var.security_group_id
  associate_public_ip_address = true

  launch_block_device_mappings = [
    {
      device_name = "/dev/sda1"
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
    }
  ]
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
