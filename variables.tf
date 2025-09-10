variable "aws_region" {
  default     = "ap-southeast-2"
  description = "AWS region"
}

variable "instance_type" {
  default     = "t3a.medium"
  description = "EC2 instance type"
}

variable "key_name" {
  description = "SSH key pair for EC2 access"
  type        = string
  default     = "testGK"
}

variable "vpc_id" {
  description = "VPC ID to launch the instance in"
  type        = string
  default     = "vpc-05c92a1e25cc19c20"
}

variable "subnet_id" {
  description = "Subnet ID for EC2"
  type        = string
  default     = "subnet-0b328702f3bb6d9cd"
}

variable "ssh_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowed SSH"
}
