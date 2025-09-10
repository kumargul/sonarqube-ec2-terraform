# SonarQube AWS EC2 Terraform Module

This Terraform module provisions a SonarQube-ready EC2 instance on AWS, including all networking and security group resources required for a basic, single-node deployment.  
Custom bootstrap installation via `userdata.sh` (install script for SonarQube, Java, PostgreSQL, etc.) is included and can be adapted to your infrastructure standards.

## Features

- Deploys Ubuntu 22.04 EC2 instance for SonarQube (Community Edition).
- Attaches a security group with open ports for SSH (22), HTTP (80), and SonarQube UI (9000).
- Supports full bootstrapping with a custom shell script (`userdata.sh`).
- Outputs the server’s public IP and DNS.

---

## Usage

```hcl
module "sonarqube_ec2" {
source = "./sonarqube-ec2-terraform"

key_name = "your-ec2-ssh-key"
vpc_id = "vpc-xxxxx"
subnet_id = "subnet-xxxxx"
ssh_cidr_blocks = ["0.0.0.0/0"] # Restrict in production!
}
```


Update and place your SonarQube install script as `userdata.sh` within the module directory.

---

## Prerequisites

- An AWS account with sufficient IAM permissions.
- A valid EC2 SSH key pair in your region.
- Pre-provisioned VPC and at least one public subnet.

---

## Inputs

| Variable         | Description                  | Default              | Required  |
|------------------|-----------------------------|----------------------|-----------|
| aws_region       | AWS region                  | `ap-southeast-2`     | No        |
| instance_type    | EC2 instance type           | `t3a.medium`         | No        |
| key_name         | Name of EC2 key pair        |                      | Yes       |
| vpc_id           | VPC ID                      |                      | Yes       |
| subnet_id        | Subnet ID for instance      |                      | Yes       |
| ssh_cidr_blocks  | Allowed CIDRs for SSH       | `["0.0.0.0/0"]`      | No        |

---

## Outputs

| Output                | Description                  |
|-----------------------|-----------------------------|
| sonarqube_public_ip   | Public IP of the SonarQube   |
| sonarqube_public_dns  | DNS of the SonarQube         |

---

## Customization & Notes

- **For Security:**  
  - Restrict SSH (`ssh_cidr_blocks`) to trusted IPs only—never leave as `0.0.0.0/0` in production.
  - Place your actual SonarQube install steps or a remote install orchestration (Ansible, SSM, etc.) in `userdata.sh`.
  - Harden the host and consider security group/OS best practices.

- **For Production:**  
  - Use AWS RDS/PostgreSQL for the database tier and point SonarQube to it, rather than local installation.
  - Consider provisioning an Application Load Balancer and using HTTPS.
  - Use root EBS volume encryption, enhanced monitoring as needed.

- **For Automation:**  
  - Outputs (public IP/DNS) can be used for DNS or health checks.
  - Add more variables for AMI, EBS size, or additional tags as required.

---

## Apply Example

```
terraform init
terraform apply -var 'key_name=your-key' -var 'vpc_id=vpc-xxxx' -var 'subnet_id=subnet-xxxx'
```


After creation, connect with SSH and verify SonarQube is reachable on port 9000 or via HTTP/HTTPS as configured.

---

## References

- [SonarQube Documentation](https://docs.sonarqube.org/latest/setup/get-started-2-minutes/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)


## Suggestions

- Add terraform destroy warning if cloud costs are a concern.

- Include a troubleshooting section with common EC2/SG/AMI issues on AWS.

- Encourage use of SSM, cloud-init, or Ansible for complex production builds.