variable "aws_region" {}
variable "source_ami" {}

variable "vpc_id" {}
variable "subnet_id" {}
variable "security_group_id" {}

variable "repo_url" {}
variable "branch" { default = "master" }
variable "app_dir" { default = "/var/www/html" }

variable "run_commands" {
  type = list(string)
}
