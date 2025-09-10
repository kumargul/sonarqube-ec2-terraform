output "sonarqube_public_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "sonarqube_public_dns" {
  value = aws_instance.sonarqube.public_dns
}
