# packer/variables.pkr.hcl

variable "aws_region" {
  type        = string
  description = "AWS region to create the AMI in"
}

variable "source_ami" {
  type        = string
  description = "The base AMI to start from"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the instance will be launched"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the instance"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach to the instance"
}


variable "workspace_path" {
  type        = string
  description = "Local workspace path to copy into the EC2 instance"
}

variable "src_dir" {
  type        = string
  description = "Destination path on the EC2 instance where workspace will be copied"
  default     = "/tmp/app"
}

variable "app_dir" {
  type        = string
  description = "Final application directory inside EC2"
  default     = "/var/www/html"
}

variable "run_commands" {
  type        = list(string)
  description = "Optional extra commands to run inside the instance"
  default     = []
}
